package pui.ui;

import haxe.extern.EitherType;
import pixi.display.Container;
import pixi.display.Graphics;
import pixi.events.InteractionEvent;
import pixi.geom.Point;
import pixi.geom.Rectangle;
import pixi.render.MaskData;
import pui.events.Event;
import pui.events.WheelEvent;
import pui.geom.Vec2;
import pui.ui.Component;

/**
 * Скроллер контента.
 * Используется для промотки содержимого, не умещающегося в область отображения.
 * 
 * Особенности:
 * 1. Скроллер не занимается оптимизацией отображения или удаления не попадающих
 * в вывод содержимого, это остаётся на совести пользователя.
 * 2. Вы также должны вызвать метод `Scroller.update()` после добавления, удаления
 * или обновления содержимого, чтобы инициировать гарантированное обновление
 * скроллера в случае изменения его содержимого.
 * 
 * @event Event.START_DRAG          Начало перетаскивания контента пользователем.
 * @event Event.STOP_DRAG           Завершение перетаскивания контента пользователем.
 * @event Event.DRAG                Перетаскивание контента пользователем.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие изначально включено.
 */
class Scroller extends Component
{
    /**
     * Тип компонента `Scroller`.
     */
    static public inline var TYPE:String = "Scroller";

    static private var RECT:Rectangle = new Rectangle(0, 0, 0, 0);
    static private var POINT:Point = new Point(0, 0);
    static private var VEC:Vec2 = new Vec2(0, 0);
    static private function OVERDRAG(x:Float, max:Float):Float {
        return 2*x*(1-x)*max + Math.pow(x,2)*max; // Кривая безье для избыточного натяжения
    }

    // Приват
    private var inputs:Array<InputData> = new Array();
    private var dragX:Float = 0;
    private var dragY:Float = 0;
    private var scrollIgnore:Bool = false;

    /**
     * Создать скроллер.
     */
    public function new() {
        super();

        componentType = TYPE;
        inputWheel = true;
        interactive = true;

        content = new Container();
        content.interactive = true;
        
        scrollV = new ScrollBar();
        scrollV.orientation = Orientation.VERTICAL;
        scrollV.on(Event.CHANGE, onScrollbarChangeV);

        scrollH = new ScrollBar();
        scrollH.orientation = Orientation.HORIZONTAL;
        scrollH.on(Event.CHANGE, onScrollbarChangeH);

        var mask = new Graphics();
        mask.beginFill(0xff0000);
        mask.drawRect(0, 0, 10, 10);
        contentMask = mask;

        Utils.set(this.updateLayers, Scroller.defaultLayers);
        Utils.set(this.updateSize, Scroller.defaultSize);

        on(WheelEvent.WHEEL, onWheel);
        on(InteractionEvent.POINTER_DOWN, onContentDown);
        on(InteractionEvent.POINTER_UP, onContentUp);
        on(InteractionEvent.POINTER_UP_OUTSIDE, onContentUp);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onScrollbarChangeV(e:Event):Void {
        if (scrollIgnore || isDragged)
            return;

        contentY = scrollV.value;

        if (velocity != null)
            velocity.speed.y = 0;

        update(false, Component.UPDATE_SIZE);
    }

    private function onScrollbarChangeH(e:Event):Void {
        if (scrollIgnore || isDragged)
            return;

        contentX = scrollH.value;

        if (velocity != null)
            velocity.speed.x = 0;

        update(false, Component.UPDATE_SIZE);
    }

    private function onContentDown(e:InteractionEvent):Void {
        
        // Перетаскивание контента мышкой.
        // Проверка актуальности события:
        if (!isActualInput(e) || drag == null || (!drag.allowX && !drag.allowY))
            return;
        
        // Целевое событие будет обработано только этим компонентом:
        e.stopPropagation();

        // Перетаскивание контента:
        on(InteractionEvent.POINTER_MOVE, onContentMove);

        // Сохраняем точку захвата:
        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        content.toLocal(POINT, null, POINT);
        dragX = POINT.x;
        dragY = POINT.y;

        // История ввода:
        if (drag.inertia != null) {
            POINT.x = e.data.global.x;
            POINT.y = e.data.global.y;
            toLocal(POINT, null, POINT);

            inputs = new Array();
            inputs[0] = { x:POINT.x, y:POINT.y, t:Utils.uptime()/1000};
        }
        
        // Обновление:
        update(false, Component.UPDATE_SIZE);

        // Событие:
        if (!isDragged) {
            isDragged = true;
            Event.fire(Event.START_DRAG, this);
        }
    }

    private function onContentMove(e:InteractionEvent):Void {

        // Перетаскивание контента мышкой.
        // Проверка актуальности события:
        if (!isActualInput(e) || drag == null || (!drag.allowX && !drag.allowY) || !isDragged) {
            off(InteractionEvent.POINTER_MOVE, onContentMove);
            if (isDragged) { // <-- Слушатель более не актуален
                isDragged = false;
                Event.fire(Event.STOP_DRAG, this);
            }
            return;
        }

        // Перетаскивание контента:
        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        toLocal(POINT, null, POINT);

        // Перетаскивание по X:
        if (drag.allowX) {
            if (velocity != null)
                velocity.speed.x = 0;

            contentX = POINT.x - dragX;

            // Избыточное натяжение:
            if (contentX > contentMaxX) {
                if (outOfBounds != null && outOfBounds.allowX) {
                    var p = Utils.eq(outW,0)?0:(Math.max(-outW, contentMaxX - contentX)/outW);
                    contentX = contentMaxX + outW * OVERDRAG(-p, Utils.nvl(drag.outDistMax, 0.5));
                }
                else
                    contentX = contentMaxX;
            }
            else if (contentX < contentMinX) {
                if (outOfBounds != null && outOfBounds.allowX) {
                    var p = Utils.eq(outW,0)?0:(Math.min(outW, contentMinX - contentX)/outW);
                    contentX = contentMinX - outW * OVERDRAG(p, Utils.nvl(drag.outDistMax, 0.5));
                }
                else
                    contentX = contentMinX;
            }
        }

        // Перетаскивание по Y:
        if (drag.allowY) {
            if (velocity != null)
                velocity.speed.y = 0;

            contentY = POINT.y - dragY;

            // Избыточное натяжение:
            if (contentY > contentMaxY) {
                if (outOfBounds != null && outOfBounds.allowY) {
                    var p = Utils.eq(outH,0)?0:(Math.max(-outH, contentMaxY - contentY)/outH);
                    contentY = contentMaxY + outH * OVERDRAG(-p, Utils.nvl(drag.outDistMax, 0.5));
                }
                else
                    contentY = contentMaxY;
            }
            else if (contentY < contentMinY) {
                if (outOfBounds != null && outOfBounds.allowY) {
                    var p = Utils.eq(outH,0)?0:(Math.min(outH, contentMinY - contentY)/outH);
                    contentY = contentMinY - outH * OVERDRAG(p, Utils.nvl(drag.outDistMax, 0.5));
                }
                else
                    contentY = contentMinY;
            }
        }

        // История ввода:
        if (drag.inertia != null) {
            if (inputs.length > 1000) // <-- Чтоб моя совесть была спокойна за утечку памяти
                inputs = new Array();

            inputs.push({ x:POINT.x, y:POINT.y, t:Utils.uptime()/1000});
        }

        // Обновление:
        update(false, Component.UPDATE_SIZE);

        // Событие:
        Event.fire(Event.DRAG, this);
    }

    private function onContentUp(e:InteractionEvent):Void {

        // Перетаскивание контента мышкой завершено.
        // Проверка актуальности события:
        if (!isActualInput(e) || drag == null || (!drag.allowX && !drag.allowY) || !isDragged)
            return;
        
        // Целевое событие будет обработано только этим компонентом:
        e.stopPropagation();
        
        // Перетаскивание контента:
        off(InteractionEvent.POINTER_MOVE, onContentMove);

        // Перетаскивание контента:
        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        toLocal(POINT, null, POINT);

        // Инерция:
        if (drag.inertia != null && velocity != null) {
            inputs.push({ x:POINT.x, y:POINT.y, t:Utils.uptime()/1000});

            VEC.x = 0;
            VEC.y = 0;

            var t = Utils.uptime()/1000 - Utils.nvl(drag.inertia.time, 0.15);
            var st:InputData = null;
            var len = inputs.length;
            var i = len;

            // Ищем начальную точку ввода:
            while (i-- != 0) {
                if (inputs[i].t < t)
                    break;
                else
                    st = inputs[i];
            }

            // Расчитываем вектор скорости:
            if (st != null) {
                i += 2;
                while (i < len) {
                    VEC.x += inputs[i].x - st.x;
                    VEC.y += inputs[i].y - st.y;
                    i ++;
                }
                
                // Передаём скорость контенту:
                if (VEC.len() >= Utils.nvl(drag.inertia.dist, 50)) {
                    velocity.speed.setFrom(VEC).mul(Utils.nvl(drag.inertia.speed, 1));
                    
                    if (!drag.inertia.allowX) velocity.speed.x = 0;
                    if (!drag.inertia.allowY) velocity.speed.y = 0;
                }
            }
        }
        
        // Обновление:
        update(false, Component.UPDATE_SIZE);

        // Событие:
        if (isDragged) {
            isDragged = false;
            Event.fire(Event.STOP_DRAG, this);
        }
    }

    private function onWheel(e:WheelEvent):Void {
        e.native.preventDefault();
        e.bubbling = false;
        
        var oldX = contentX;
        var oldY = contentY;
        if (e.native.deltaX > 0) {
            contentX += scrollDist;
            if (contentX > contentMaxX)
                contentX = contentMaxX;
            if (velocity != null)
                velocity.speed.x = 0;
        }
        else if (e.native.deltaX < 0) {
            contentX -= scrollDist;
            if (contentX < contentMinX)
                contentX = contentMinX;
            if (velocity != null)
                velocity.speed.x = 0;
        }

        if (e.native.deltaY > 0) {
            contentY -= scrollDist;
            if (contentY < contentMinY)
                contentY = contentMinY;
            if (velocity != null)
                velocity.speed.y = 0;
        }
        else if (e.native.deltaY < 0) {
            contentY += scrollDist;
            if (contentY > contentMaxY)
                contentY = contentMaxY;
            if (velocity != null)
                velocity.speed.y = 0;
        }

        if (oldX != contentX || oldY != contentY)
            update(false, Component.UPDATE_SIZE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Перетаскивание контента. (Флаг состояния)
     * - Равно `true`, когда пользователь перетаскивает содержимое скроллера.
     * - Это значение управляется автоматически, вы не можете его изменить.
     * - При изменении значения посылаются события: `DragEvent.START` и `DragEvent.STOP`.
     * 
     * По умолчанию: `false`
     */
    public var isDragged(default, null):Bool = false;

    /**
     * Ширина области вывода. (px)
     * 
     * Содержит текущую, доступную ширину области отображения.
     * Эта область меньше или равна ширине компонента `w`.
     * На её размеры может влиять наличие ползунков.
     * 
     * Это значение всегда целочисленно.
     * 
     * Расчитывается каждый раз заного при обновлении. 
     */
    public var outW(default, null):Float = 0;

     /**
      * Высота области вывода. (px)
      * 
      * Содержит текущую, доступную высоту области отображения.
      * Эта область меньше или равна высоте компонента `h`.
      * На её размеры может влиять наличие ползунков.
      * 
      * Это значение всегда целочисленно.
      * 
      * Расчитывается каждый раз заного при обновлении. 
      */
    public var outH(default, null):Float = 0;

    /**
     * Контейнер с содержимым.
     * 
     * Вы **должны** добавлять новый контент именно сюда, а не в сам скроллер.
     * Вы можете задать размеры содержимого в свойстве `contentBounds`, в противном
     * случае, размеры будет вычисляться каждый раз автоматически при обновлении.
     * 
     * Не может быть `null`
     */
    public var content(default, null):Container;

    /**
     * Маска контента.
     * 
     * Используется как обычная маска pixijs, для обрезания области отображения,
     * выходящей за границы компонента. При каждом обновлении маске задаются
     * ширина и высота области отображения.
     * 
     * Если задать `null` - контент не будет обрезаться. 
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию используется экземпляр `Graphics` 10x10. (Коробка)
     */
    public var contentMask(default, set):EitherType<Container,MaskData> = null;
    function set_contentMask(value:EitherType<Container,MaskData>):EitherType<Container,MaskData> {
        if (Utils.eq(value, contentMask))
            return value;

        Utils.hide(this, contentMask);
        contentMask = value;
        content.mask = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Привязка позиции контейнера к целочисленным координатам:
     * - Если `true`, позиция контейнера будет округляться: `x,y=Math.round(contentX,contentY)`.
     * - Если `false`, позиция контейнера будет смещаться более плавно, но изображение
     *   может стать размытым.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `true` (Целочисленные координаты)
     */
    public var pixelHinting(default, set):Bool = true;
    function set_pixelHinting(value:Bool):Bool {
        if (Utils.eq(value, pixelHinting))
            return value;
        
        pixelHinting = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Позиция контейнера с содержимым `content` по оси X. (px)
     * 
     * Это значение используется для позицианирования контейнера с содержимым.
     * Эта отдельная переменная нужна для того, что бы сохранить точность и 
     * плавность вычислений при включенном режиме `pixelHinting`.
     * 
     * Изменение значения не регистрирует обновление компонента.
     * Для работы с позицией содержимого вы должны использовать это значение.
     * 
     * По умолчанию: `0`
     */
    public var contentX:Float = 0;

    /**
     * Минимальное значение `contentX`. (px)
     * 
     * Это значение указывает крайнюю левую позицию для контейнера с содержимым.
     * Расчитывается заного при каждом обновлений.
     * Изменение значения не регистрирует обновление компонента.
     * 
     * По умолчанию: `0`
     */
    public var contentMinX(default, null):Float = 0;

    /**
     * Максимальное значение `contentX`. (px)
     * 
     * Это значение указывает крайнюю правую позицию для контейнера с содержимым.
     * Расчитывается заного при каждом обновлений.
     * Изменение значения не регистрирует обновление компонента.
     * 
     * По умолчанию: `0`
     */
    public var contentMaxX(default, null):Float = 0;

    /**
     * Позиция контейнера с содержимым `content` по оси Y. (px)
     * 
     * Это значение используется для позицианирования контейнера с содержимым.
     * Эта отдельная переменная нужна для того, что бы сохранить точность и 
     * плавность вычислений при включенном режиме `pixelHinting`.
     * 
     * Изменение значения не регистрирует обновление компонента.
     * Для работы с позицией содержимого вы должны использовать это значение.
     * 
     * По умолчанию: `0`
     */
    public var contentY:Float = 0;

    /**
     * Минимальное значение `contentY`. (px)
     * 
     * Это значение указывает крайнюю верхнюю позицию для контейнера с содержимым.
     * Расчитывается заного при каждом обновлений.
     * Изменение значения не регистрирует обновление компонента.
     * 
     * По умолчанию: `0`
     */
    public var contentMinY(default, null):Float = 0;

    /**
     * Максимальное значение `contentY`. (px)
     * 
     * Это значение указывает крайнюю нижнюю позицию для контейнера с содержимым.
     * Расчитывается заного при каждом обновлений.
     * Изменение значения не регистрирует обновление компонента.
     * 
     * По умолчанию: `0`
     */
    public var contentMaxY(default, null):Float = 0;

    /**
     * Область контента.
     * 
     * Этот прямоугольник позволяет задать произвольные размеры содержимого
     * скроллера, даже если он пуст. Если это значение задано, скроллер будет
     * исходить из этих параметров размеров контента, а не фактических. Это
     * может быть полезно, если ваш контент имеет динамический размер, а так же
     * для повышения быстродействия.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null` (Скроллер исходит из фактических размеров добавленного в него содержимого)
     */
    public var contentBounds(default, set):Rectangle = null;
    function set_contentBounds(value:Rectangle):Rectangle {
        contentBounds = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Нативно вычисленная области контента.
     * 
     * Используется для получения размеров содержимого, когда пользователем
     * не задано `contentBounds`. В этом случае расчитывается при каждом
     * обновлении скроллера и сохраняет объект в это свойство.
     * 
     * По умолчанию: `null`
     */
    public var contentBoundsNative(default, null):Rectangle = null;

    /**
     * Горизонтальный ползунок.
     * 
     * Не может быть `null`
     */
    public var scrollH(default, null):ScrollBar;

    /**
     * Вертикальный ползунок.
     * 
     * Не может быть `null`
     */
    public var scrollV(default, null):ScrollBar;

    /**
     * Дистанция прокрутки. (px)
     * 
     * Используется для указания прокручиваемой области при скролле
     * кнопками ползунков или при вращении колёсика мыши.
     * 
     * По умолчанию: `100`
     */
    public var scrollDist:Float = 100;

    /**
     * Режим отображения содержимого по оси X.
     * 
     * Позволяет управлять отображением горизонтальной полосы прокрутки.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `Overflow.AUTO`
     */
    public var overflowX(default, set):Overflow = Overflow.AUTO;
    function set_overflowX(value:Overflow):Overflow {
        if (Utils.eq(overflowX, value))
            return value;

        overflowX = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }
 
    /**
     * Режим отображения содержимого по оси Y.
     * 
     * Позволяет управлять отображением вертикальной полосы прокрутки.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `Overflow.AUTO`
     */
    public var overflowY(default, set):Overflow = Overflow.AUTO;
    function set_overflowY(value:Overflow):Overflow {
        if (Utils.eq(overflowY, value))
            return value;

        overflowY = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Параметры выхода содержимого за границы своей области.
     * 
     * Выход за границы разрешённой области - это когда позиция контейнера
     * с содержимым оказывается за границами отображения. Эти параметры
     * позволяют настроить такой выход.
     * 
     * По умолчанию: `null` (Контент не может оказаться за пределами отображения)
     */
    public var outOfBounds:OutOfBoundsParam = null;

     /**
      * Параметры управления перетаскиванием контента мышкой или касанием.
      * 
      * Не может быть `null`
      */
    public var drag:DragParams = null;
 
     /**
      * Параметры скорости движения контента.
      * 
      * Не может быть `null`
      */
    public var velocity:VelocityParams = null;



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Выгрузить скроллер.
	 */
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        scrollV.destroy(options);
        Utils.delete(scrollV);
        
        scrollH.destroy(options);
        Utils.delete(scrollH);

        Utils.delete(drag);
        Utils.delete(velocity);
        Utils.delete(outOfBounds);

        super.destroy(options);
    }



    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв скроллера.
     */
    static public var defaultLayers:LayersUpdater<Scroller> = function(sc) {
        if (sc.enabled) {
            Utils.show(sc, sc.skinBg);
            Utils.hide(sc, sc.skinBgDisable);

            Utils.show(sc, sc.contentMask);
            Utils.show(sc, sc.content);
        }
        else {
            if (Utils.eq(sc.skinBgDisable, null)) {
                Utils.show(sc, sc.skinBg);
                Utils.hide(sc, sc.skinBgDisable);
    
                Utils.show(sc, sc.contentMask);
                Utils.show(sc, sc.content);
            }
            else {
                Utils.hide(sc, sc.skinBg);
                Utils.show(sc, sc.skinBgDisable);
    
                Utils.show(sc, sc.contentMask);
                Utils.show(sc, sc.content);
            }
        }

        // Отображение этих элементов управляется функцией позицианирования,
        // тут мы просто помещаем их на нужное место в порядке дисплей листа,
        // если они уже отображаются:
        if (Utils.noeq(sc.scrollH, null) && Utils.eq(sc.scrollH.parent, sc))
            sc.addChild(sc.scrollH);
        if (Utils.noeq(sc.scrollH, null) && Utils.eq(sc.scrollV.parent, sc))
            sc.addChild(sc.scrollH);
    }

    /**
     * Обычное позицианирование скроллера.
     */
    static public var defaultSize:SizeUpdater<Scroller> = function(sc) {
        Utils.size(sc.skinBg, sc.w, sc.h);
        Utils.size(sc.skinBgDisable, sc.w, sc.h);
        
        // Требуется ещё одно обновление:
        var needUPD = false;

        // Первичное обновление ползунков:
        if (!sc.scrollH.isInit) sc.scrollH.update(true);
        if (!sc.scrollV.isInit) sc.scrollV.update(true);

        // Размеры контента:
        var b = sc.contentBounds;
        if (Utils.eq(b, null)) {
            b = sc.contentBoundsNative;
            if (Utils.eq(b, null)) {
                b = new Rectangle(0,0,0,0);
                sc.contentBoundsNative = b;
            }
            sc.content.getLocalBounds(b);
        }

        // Наличие ползунков:
        var sh = Utils.eq(sc.overflowX, Overflow.SCROLL) || (Utils.eq(sc.overflowX, Overflow.AUTO) && b.width > sc.w);
        var sv = Utils.eq(sc.overflowY, Overflow.SCROLL) || (Utils.eq(sc.overflowY, Overflow.AUTO) && b.height > sc.h);

        // Порт вывода:
        sc.outW = sv?Math.max(0,sc.w-sc.scrollV.w):sc.w;
        sc.outH = sh?Math.max(0,sc.h-sc.scrollH.h):sc.h;

        // Диапазон движения контейнера:
        sc.contentMaxX = -b.x;
        sc.contentMaxY = -b.y;
        sc.contentMinX = b.width > sc.outW?(-b.x-(b.width-sc.outW)):-b.x;
        sc.contentMinY = b.height > sc.outH?(-b.y-(b.height-sc.outH)):-b.y;

        // Управление позицией контента:
        if (!sc.isDragged) {

            // Движение контента:
            if (    sc.velocity != null && 
                    (sc.velocity.allowX || sc.velocity.allowY) && 
                    (Utils.noeq(sc.velocity.speed.x, 0) || Utils.noeq(sc.velocity.speed.y, 0))
            ) {
                
                // Затухание:
                var v:Float = Utils.nvl(sc.velocity.speedDmp, 0.75);
                if (v > 0)
                    sc.velocity.speed.mul(Math.max(0, 1 - v * sc.theme.dt));

                // Максимум:
                if (sc.velocity.speedMax > 0 && sc.velocity.speed.len() > sc.velocity.speedMax)
                    sc.velocity.speed.nrm().mul(sc.velocity.speedMax);

                // Минимум:
                v = Utils.nvl(sc.velocity.speedMin, 3);
                if (v > 0 && sc.velocity.speed.len() < v)
                    sc.velocity.speed.set(0, 0);
                else 
                    needUPD = true;
                
                // Движение по X:
                if (sc.velocity.allowX) {
                    if (sc.velocity.speed.x > 0) {
                        if (sc.contentX < sc.contentMaxX) {
                            sc.contentX += sc.velocity.speed.x * sc.theme.dt;
                            if (sc.contentX >= sc.contentMaxX) {
                                sc.contentX = sc.contentMaxX;
                                sc.velocity.speed.x = 0;
                            }
                        }
                        else
                            sc.velocity.speed.x = 0;
                    }
                    else if (sc.velocity.speed.x < 0) {
                        if (sc.contentX > sc.contentMinX) {
                            sc.contentX += sc.velocity.speed.x * sc.theme.dt;
                            if (sc.contentX <= sc.contentMinX) {
                                sc.contentX = sc.contentMinX;
                                sc.velocity.speed.x = 0;
                            }
                        }
                        else
                            sc.velocity.speed.x = 0;
                    }
                }

                // Движение по Y:
                if (sc.velocity.allowY) {
                    if (sc.velocity.speed.y > 0) {
                        if (sc.contentY < sc.contentMaxY) {
                            sc.contentY += sc.velocity.speed.y * sc.theme.dt;
                            if (sc.contentY >= sc.contentMaxY) {
                                sc.contentY = sc.contentMaxY;
                                sc.velocity.speed.y = 0;
                            }
                        }
                        else
                            sc.velocity.speed.y = 0;
                    }
                    else if (sc.velocity.speed.y < 0) {
                        if (sc.contentY > sc.contentMinY) {
                            sc.contentY += sc.velocity.speed.y * sc.theme.dt;
                            if (sc.contentY <= sc.contentMinY) {
                                sc.contentY = sc.contentMinY;
                                sc.velocity.speed.y = 0;
                            }
                        }
                        else
                            sc.velocity.speed.y = 0;
                    }
                }
            }
            
            // Ограничение области нахождения контента по X:
            if (sc.contentX > sc.contentMaxX) {
                if (sc.outOfBounds != null && sc.outOfBounds.allowX) {
                    var dist = sc.contentMaxX - sc.contentX;
                    if (dist < -1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        sc.contentX += Utils.nvl(sc.outOfBounds.speedBack, 25) * sc.theme.dt * dist;
                        if (sc.contentX <= sc.contentMaxX)
                            sc.contentX = sc.contentMaxX;
                        else
                            needUPD = true;
                    }
                    else
                        sc.contentX = sc.contentMaxX;
                }
                else
                    sc.contentX = sc.contentMaxX;
            }
            else if (sc.contentX < sc.contentMinX) {
                if (sc.outOfBounds != null && sc.outOfBounds.allowX) {
                    var dist = sc.contentMinX - sc.contentX;
                    if (dist > 1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        sc.contentX += Utils.nvl(sc.outOfBounds.speedBack, 25) * sc.theme.dt * dist;
                        if (sc.contentX >= sc.contentMinX)
                            sc.contentX = sc.contentMinX;
                        else
                            needUPD = true;
                    }
                    else
                        sc.contentX = sc.contentMinX;
                }
                else
                    sc.contentX = sc.contentMinX;
            }

            // Ограничение области нахождения контента по Y:
            if (sc.contentY > sc.contentMaxY) {
                if (sc.outOfBounds != null && sc.outOfBounds.allowY) {
                    var dist = sc.contentMaxY - sc.contentY;
                    if (dist < -1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        sc.contentY += Utils.nvl(sc.outOfBounds.speedBack, 25) * sc.theme.dt * dist;
                        if (sc.contentY <= sc.contentMaxY)
                            sc.contentY = sc.contentMaxY;
                        else
                            needUPD = true;
                    }
                    else
                        sc.contentY = sc.contentMaxY;
                }
                else
                    sc.contentY = sc.contentMaxY;
            }
            else if (sc.contentY < sc.contentMinY) {
                if (sc.outOfBounds != null && sc.outOfBounds.allowY) {
                    var dist = sc.contentMinY - sc.contentY;
                    if (dist > 1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        sc.contentY += Utils.nvl(sc.outOfBounds.speedBack, 25) * sc.theme.dt * dist;
                        if (sc.contentY >= sc.contentMinY)
                            sc.contentY = sc.contentMinY;
                        else
                            needUPD = true;
                    }
                    else
                        sc.contentY = sc.contentMinY;
                }
                else
                    sc.contentY = sc.contentMinY;
            }
        }

        // Позицианирование:
        if (sc.pixelHinting) {
            sc.content.x = Math.round(sc.contentX);
            sc.content.y = Math.round(sc.contentY);
        }
        else {
            sc.content.x = sc.contentX;
            sc.content.y = sc.contentY;
        }

        // Маска:
        Utils.size(sc.contentMask, sc.outW, sc.outH);

        // Ползунки:
        sc.scrollIgnore = true;
        sc.scrollH.enabled = sc.enabled?(sc.outW < b.width):false;
        if (sh) {
            sc.scrollH.w = sc.outW;
            sc.scrollH.y = sc.outH;
            sc.scrollH.min = sc.contentMinX;
            sc.scrollH.max = sc.contentMaxX;
            sc.scrollH.value = sc.contentX;
            sc.scrollH.thumbScale = sc.outW / b.width;
            sc.scrollH.step = sc.scrollDist;
            sc.scrollH.invert = true;
            Utils.show(sc, sc.scrollH);
        }
        else {
            Utils.hide(sc, sc.scrollH);
        }
        sc.scrollV.enabled = sc.enabled?(sc.outH < b.height):false;
        if (sv) {
            sc.scrollV.h = sc.outH;
            sc.scrollV.x = sc.outW;
            sc.scrollV.min = sc.contentMinY;
            sc.scrollV.max = sc.contentMaxY;
            sc.scrollV.value = sc.contentY;
            sc.scrollV.thumbScale = sc.outH / b.height;
            sc.scrollV.step = sc.scrollDist;
            sc.scrollV.invert = true;
            Utils.show(sc, sc.scrollV);
        }
        else {
            Utils.hide(sc, sc.scrollV);
        }
        sc.scrollIgnore = false;

        // Анимация не завершена:
        if (needUPD)
            sc.updateNext(Component.UPDATE_SIZE);
    }
}

/**
 * Параметры выхода содержимого за пределы доступной зоны.
 */
typedef OutOfBoundsParam = 
{
    /**
     * Разрешение на выход за пределы доступной зоны по оси X.
     */
    @:optional var allowX:Bool;

    /**
     * Разрешение на выход за пределы доступной зоны по оси Y.
     */
    @:optional var allowY:Bool;

    /**
     * Скорость возврата контента на своё место. (scale/sec)
     * 
     * Это скалярное значение, во сколько раз сократится дистанция контента до его
     * корректного местоположения за 1 секунду. Используется для возврата контента
     * на своё место.
     * 
     * Если не задано, используется значение по умолчанию: `25`
     */
    @:optional var speedBack:Float;
}

/**
 * Параметры перетаскивания содержимого курсором или касанием.
 */
typedef DragParams = 
{
    /**
     * Разрешение на перетаскивание содержимого по оси X.
     */
    @:optional var allowX:Bool;

    /**
     * Разрешение на перетаскивание содержимого по оси Y.
     */
    @:optional var allowY:Bool;

    /**
     * Максимальная дистанция выхода за пределы доступной зоны. (0-1)
     * 
     * Значение используется для задания максимальной дистанции выхода контета
     * за пределы доступной области отображения, где начение `1` - соответствует
     * ширине и высоте самого компонента, для осей **x** и **y** соответственно.
     * 
     * пс. Это значение работает только при включенном режиме выхода за пределы:
     * `outOfBoundsParam`.
     * 
     * Если не задано, используется значение по умолчанию: `0.5`. (Выход до середины)
     */
    @:optional var outDistMax:Float;

    /**
     * Параметры инерции.
     * 
     * Позволяет запускать содержимое списка в полёт при помощи резкого свапа.
     * 
     * Если не задано, инерция будет отключена.
     */
    @:optional var inertia:InertiaParams;
}

/**
 * Параметры инерции.
 */
typedef InertiaParams = 
{
    /**
     * Инерция разрешена по оси X.
     */
    @:optional var allowX:Bool;

     /**
      * Инерция разрешена по оси Y.
      */
    @:optional var allowY:Bool;

    /**
     * Интервал времени для расчёта свапа. (sec)
     * 
     * Этот промежуток времени используется для расчёта свапа.
     * Чем он больше, тем больше последних событий ввода будут
     * учавствовать в расчётах.
     * 
     * Если не задано, используется значение по умолчанию: `0.15`
     */
    @:optional var time:Float;

    /**
     * Множитель задаваемой скорости. (scale)
     * 
     * Если не задано, используется значение по умолчанию: `1` (100%)
     */
    @:optional var speed:Float;

    /**
     * Минимальная, пройденная дистанция для засчитывания свапа. (px)
     * 
     * Если не задано, используется значение по умолчанию: `50`
     */
    @:optional var dist:Float;
}

/**
 * Параметры движения контента скроллера.
 */
typedef VelocityParams = 
{
    /**
     * Разрешение на движение по оси X.
     */
    @:optional var allowX:Bool;

     /**
      * Разрешение на движение по оси Y.
      */
    @:optional var allowY:Bool;

    /**
     * Скорость перемещения контента. (px/sec)
     * 
     * Вектор описывает скорость и направление движения контента в
     * рамках разрешённой области скроллинга.
     * 
     * Не может быть `null`
     */
    var speed(default, null):Vec2;

    /**
     * Максимальная скорость движения контента. (px/sec)
     * 
     * Если задано, используется для ограничения максимальной скорости
     * перемещения контента.
     */
    @:optional var speedMax:Float;

    /**
     * Минимальная скорость движения контента. (px/sec)
     * 
     * Если задано, используется для ограничения минимальной скорости
     * перемещения контента. Скорость ниже этого значения сбрасывается
     * до нуля.
     * 
     * Если не задано, используется значение по умолчанию: `3`
     */
    @:optional var speedMin:Float;

    /**
     * Коэффициент торможения. (scale/sec)
     * 
     * Используется для плавного затухания скорости движения.
     * Это скалярное значение, в сколько раз уменьшится скорость за 1 секунду.
     * 
     * Если не задано, используется значение по умолчанию: `0.75`
     */
    @:optional var speedDmp:Float;
}

/**
 * Параметры ввода.
 * Используется для хранения пользовательской информации ввода.
 */
typedef InputData = 
{
    /**
     * Позиция ввода по X. (px)
     */
    var x:Float;

    /**
     * Позиция ввода по Y. (px)
     */
    var y:Float;

    /**
     * Дата с момента запуска приложения. (sec)
     */
    var t:Float;
}