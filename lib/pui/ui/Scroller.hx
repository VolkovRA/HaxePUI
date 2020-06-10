package pui.ui;

import pui.dom.PointerType;
import pui.events.Event;
import pui.events.DragEvent;
import pui.events.WheelEvent;
import pui.geom.Vec2;
import pui.ui.Component;
import pui.pixi.PixiEvent;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.graphics.Graphics;
import pixi.core.math.Point;
import pixi.core.math.shapes.Rectangle;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

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
 * @event DragEvent.START           Начало перетаскивания контента пользователем.
 * @event DragEvent.STOP            Завершение перетаскивания контента пользователем.
 * @event DragEvent.MOVE            Перетаскивание контента пользователем.
 * @event DragEvent.OVERDRAG        Перетаскивание контента пользователем за пределы доступной зоны.
 * @event ComponentEvent.UPDATE     Обновление компонента. (Перерисовка)
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
    static private function OVERDRAG(x:Float, max:Float):Float {
        return 2*x*(1-x)*max + Math.pow(x,2)*max; // Кривая безье для избыточного натяжения
    }

    // Приват
    private var contentMask:Graphics;
    private var scrollIgnore:Bool = false;
    private var scrollSetX:Float = -1;
    private var scrollSetY:Float = -1;
    private var isDragging:Bool = false;
    private var dragX:Float = 0;
    private var dragY:Float = 0;
    private var dragContentX:Float = 0;
    private var dragContentY:Float = 0;
    private var wheelScrollX:Float = 0;
    private var wheelScrollY:Float = 0;
    private var inputs:Array<InputData> = new Array();

    /**
     * Создать скроллер.
     */
    public function new() {
        super(TYPE);

        inputWheel = true;
        on(WheelEvent.WHEEL, onWheel);

        contentMask = new Graphics();
        contentMask.beginFill(0xff0000);
        contentMask.drawRect(0, 0, 10, 10);

        content = new Container();
        content.interactive = true;
        content.on(PixiEvent.POINTER_DOWN, onContentDown);
        content.on(PixiEvent.POINTER_UP, onContentUp);
        content.on(PixiEvent.POINTER_UP_OUTSIDE, onContentUp);
        content.mask = contentMask;

        scrollV = new ScrollBar();
        scrollV.min = 0;
        scrollV.max = 1;
        scrollV.orientation = Orientation.VERTICAL;
        scrollV.on(Event.CHANGE, onScrollbarChangeV);
        scrollV.update(true);

        scrollH = new ScrollBar();
        scrollH.min = 0;
        scrollH.max = 1;
        scrollH.orientation = Orientation.HORIZONTAL;
        scrollH.on(Event.CHANGE, onScrollbarChangeH);
        scrollH.update(true);

        Utils.set(this.updateLayers, Scroller.defaultLayers);
        Utils.set(this.updateSize, Scroller.defaultSize);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onScrollbarChangeV(e:Event):Void {
        if (scrollIgnore)
            return;

        scrollSetY = scrollV.value;
        update(false, Component.UPDATE_SIZE);
    }

    private function onScrollbarChangeH(e:Event):Void {
        if (scrollIgnore)
            return;

        scrollSetX = scrollH.value;
        update(false, Component.UPDATE_SIZE);
    }

    private function onContentDown(e:InteractionEvent):Void {
        if (!dragParams.enabled || !enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        e.stopPropagation();

        // Перетаскивание контента:
        if (dragParams.enabled) {
            content.on(PixiEvent.POINTER_MOVE, onContentMove);

            isDragging = true;
    
            // Save
            POINT.x = e.data.global.x;
            POINT.y = e.data.global.y;
            content.toLocal(POINT, null, POINT);
            dragX = POINT.x;
            dragY = POINT.y;
    
            // Drag
            POINT.x = e.data.global.x;
            POINT.y = e.data.global.y;
            toLocal(POINT, null, POINT);
    
            dragContentX = POINT.x - dragX;
            dragContentY = POINT.y - dragY;
    
            // Инерция:
            if (dragParams.enabled && dragParams.inertia.enabled) {
                inputs = new Array();
                inputs[0] = { x:POINT.x, y:POINT.y, t:Utils.uptime() / 1000};
            }
            
            update(false, Component.UPDATE_SIZE);

            // Событие:
            var e = DragEvent.get(DragEvent.START, this);
            emit(DragEvent.START, e);
            DragEvent.store(e);
        }
    }

    private function onContentMove(e:InteractionEvent):Void {
        if (!dragParams.enabled || !enabled || (inputPrimary && !e.data.isPrimary))
            return;

        // Перетаскивание контента:
        if (dragParams.enabled) {
            POINT.x = e.data.global.x;
            POINT.y = e.data.global.y;
            toLocal(POINT, null, POINT);

            dragContentX = POINT.x - dragX;
            dragContentY = POINT.y - dragY;

            // Инерция:
            if (dragParams.inertia.enabled) {
                if (inputs.length > 1000) // <-- Чтоб моя совесть была спокойна за утечку памяти
                    inputs = new Array();

                inputs.push({ x:POINT.x, y:POINT.y, t:Utils.uptime() / 1000});
            }

            update(false, Component.UPDATE_SIZE);
        }
    }

    private function onContentUp(e:InteractionEvent):Void {
        if (!dragParams.enabled || !enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        content.off(PixiEvent.POINTER_MOVE, onContentMove);
        isDragging = false;

        // Перетаскивание контента:
        if (dragParams.enabled) {
            POINT.x = e.data.global.x;
            POINT.y = e.data.global.y;
            toLocal(POINT, null, POINT);

            // Инерция:
            if (dragParams.inertia.enabled) {
                inputs.push({ x:POINT.x, y:POINT.y, t:Utils.uptime() / 1000});

                var t = Utils.uptime() / 1000 - dragParams.inertia.time;
                var vel:Vec2 = new Vec2();
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
                        vel.x += inputs[i].x - st.x;
                        vel.y += inputs[i].y - st.y;
                        i ++;
                    }

                    // Передаём скорость контенту:
                    if (vel.len() > dragParams.inertia.dist && velocity.enabled)
                        velocity.speed.setFrom(vel).mul(dragParams.inertia.speed);
                }
            }

            update(false, Component.UPDATE_SIZE);

            // Событие:
            var e = DragEvent.get(DragEvent.STOP, this);
            emit(DragEvent.STOP, e);
            DragEvent.store(e);
        }
    }

    private function onWheel(e:WheelEvent):Void {
        e.native.preventDefault();
        e.bubbling = false;

        if (e.native.deltaX > 0)
            wheelScrollX += wheelScrollDist;
        else if (e.native.deltaX < 0)
            wheelScrollX -= wheelScrollDist;

        if (e.native.deltaY > 0)
            wheelScrollY -= wheelScrollDist;
        else if (e.native.deltaY < 0)
            wheelScrollY += wheelScrollDist;

        update(false, Component.UPDATE_SIZE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        if (!value) {
            content.off(PixiEvent.POINTER_MOVE, onContentMove);
            isDragging = false;
        }

        scrollH.enabled = value;
        scrollV.enabled = value;
        return super.set_enabled(value);

    }

    /**
     * Контейнер с содержимым скроллера.
     * Вы должны добавлять контент в скроллер именно сюда, а не в сам скроллер.
     * 
     * Не может быть `null`
     */
    public var content(default, null):Container;

    /**
     * Позиция контейнера с содержимым по оси X.
     * 
     * Это значение используется для позицианирования контейнера с содержимым.
     * Эта отдельная переменная создана для того, что бы сохранить точность и 
     * плавность вычислений и округлить реальную позицию самого контейнера.
     * (Контейнер позицианируется по целочисленным координатам)
     * 
     * ```
     * content.x = Math.round(contentX);
     * content.y = Math.round(contentY);
     * ```
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`
     */
    public var contentX(default, set):Float = 0;
    function set_contentX(value:Float):Float {
        if (Utils.eq(value, contentX))
            return value;

        contentX = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Позиция контейнера с содержимым по оси Y.
     * 
     * Это значение используется для позицианирования контейнера с содержимым.
     * Эта отдельная переменная создана для того, что бы сохранить точность и 
     * плавность вычислений и округлить реальную позицию самого контейнера.
     * (Контейнер позицианируется по целочисленным координатам)
     * 
     * ```
     * content.x = Math.round(contentX);
     * content.y = Math.round(contentY);
     * ```
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`
     */
    public var contentY(default, set):Float = 0;
    function set_contentY(value:Float):Float {
        if (Utils.eq(value, contentY))
            return value;

        contentY = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скорость возврата контента на место. (scale/sec)
     * 
     * Это скалярное значение, в сколько раз сократится дистанция контента до его
     * корректного местоположения за 1 секунду. Используется для возврата контента
     * на место, если по каким то причинам он вышел за пределы дозволеной области.
     * 
     * По умолчанию: `25`
     */
    public var contentBackSpeed(default, set):Float = 25;
    function set_contentBackSpeed(value:Float):Float {
        if (value > 0)
            contentBackSpeed = value;
        else
            contentBackSpeed = 0;

        return value;
    }

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
     * Горизонтальный ползунок.
     * Не может быть `null`
     */
    public var scrollH(default, null):ScrollBar;

    /**
     * Вертикальный ползунок.
     * Не может быть `null`
     */
    public var scrollV(default, null):ScrollBar;

    /**
     * Дистанция смещения контента при прокрутке колёсиком мыши. (px)
     * По умолчанию: `100`
     */
    public var wheelScrollDist:Float = 100;

    /**
     * Параметры управления свапом. (Перетаскивание пальцем/курсором)
     * Не может быть `null`
     */
    public var dragParams(default, null):DragParams = {
        enabled: true,
        overdrag: {
            enabled: true,
            distMax: 0.5,
        },
        inertia: {
            enabled: true,
            speed:   1,
            dist:    50,
            time:    0.1,
        }
    }

    /**
     * Параметры скорости движения контента.
     * Не может быть `null`
     */
    public var velocity(default, null):VelocityParams = {
        enabled: true,
        speed: new Vec2(0, 0),
        speedMax: 0,
        speedMin: 3,
        speedDmp: 0.75
    }

    //public var wheel

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



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Выгрузить скроллер.
	 */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        scrollV.destroy(options);
        Utils.delete(scrollV);
        
        scrollH.destroy(options);
        Utils.delete(scrollH);

        Utils.delete(dragParams);
        Utils.delete(velocity);

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
        
        // События: (Диспетчерезируются в конце)
        var evDrag:DragEvent = null;
        var evDragOver:DragEvent = null;

        // Требуется ещё одно обновление:
        var needUPD = false;

        // Размеры контента:
        var b = sc.contentBounds;
        if (Utils.eq(b, null))
            b = sc.content.getLocalBounds(RECT);

        // Наличие ползунков:
        var sh = Utils.eq(sc.overflowX, Overflow.SCROLL) || (Utils.eq(sc.overflowX, Overflow.AUTO) && b.width > sc.w);
        var sv = Utils.eq(sc.overflowY, Overflow.SCROLL) || (Utils.eq(sc.overflowY, Overflow.AUTO) && b.height > sc.h);

        // Порт вывода:
        var outW = sv?Math.max(0,sc.w-sc.scrollV.w):sc.w;
        var outH = sh?Math.max(0,sc.h-sc.scrollH.h):sc.h;
        var minX = b.width > outW?(-b.x-(b.width-outW)):-b.x;
        var minY = b.height > outH?(-b.y-(b.height-outH)):-b.y;

        // Ограничение позиции контента:
        if (sc.isDragging) {
            sc.velocity.speed.set(0, 0);
            
            // Режим перетаскивания контента курсором.
            // Событие:
            if (Utils.eq(evDrag, null))
                evDrag = DragEvent.get(DragEvent.MOVE, sc);

            // Избыточное натяжение по X:
            if (sc.dragContentX > -b.x) {
                if (sc.dragParams.overdrag.enabled) {
                    if (Utils.eq(evDragOver, null))
                        evDragOver = DragEvent.get(DragEvent.OVERDRAG, sc);
                    evDragOver.overdragX = -b.x - sc.dragContentX;
                    
                    var p = Utils.eq(outW,0)?0:(Math.max(-outW, -b.x - sc.dragContentX)/outW);
                    Utils.set(sc.contentX, -b.x + outW * OVERDRAG(-p, sc.dragParams.overdrag.distMax));
                }
                else {
                    Utils.set(sc.contentX, sc.dragContentX);
                }
            }
            else if (sc.dragContentX < minX) {
                if (sc.dragParams.overdrag.enabled) {
                    if (Utils.eq(evDragOver, null))
                        evDragOver = DragEvent.get(DragEvent.OVERDRAG, sc);
                    evDragOver.overdragX = minX - sc.dragContentX;
                    
                    var p = Utils.eq(outW,0)?0:(Math.min(outW, minX - sc.dragContentX)/outW);
                    Utils.set(sc.contentX, minX - outW * OVERDRAG(p, sc.dragParams.overdrag.distMax));
                }
                else {
                    Utils.set(sc.contentX, sc.dragContentX);
                }
            }
            else {
                Utils.set(sc.contentX, sc.dragContentX);
            }

            // Избыточное натяжение по Y:
            if (sc.dragContentY > -b.y) {
                if (sc.dragParams.overdrag.enabled) {
                    if (Utils.eq(evDragOver, null))
                        evDragOver = DragEvent.get(DragEvent.OVERDRAG, sc);
                    evDragOver.overdragY = -b.y - sc.dragContentY;

                    var p = Utils.eq(outH,0)?0:(Math.max(-outH, -b.y - sc.dragContentY)/outH);
                    Utils.set(sc.contentY, -b.y + outH * OVERDRAG(-p, sc.dragParams.overdrag.distMax));
                }
                else {
                    Utils.set(sc.contentY, sc.dragContentY);
                }
            }
            else if (sc.dragContentY < minY) {
                if (sc.dragParams.overdrag.enabled) {
                    if (Utils.eq(evDragOver, null))
                        evDragOver = DragEvent.get(DragEvent.OVERDRAG, sc);
                    evDragOver.overdragY = minY - sc.dragContentY;

                    var p = Utils.eq(outH,0)?0:(Math.min(outH, minY - sc.dragContentY)/outH);
                    Utils.set(sc.contentY, minY - outH * OVERDRAG(p, sc.dragParams.overdrag.distMax));
                }
                else {
                    Utils.set(sc.contentY, sc.dragContentY);
                }
            }
            else {
                Utils.set(sc.contentY, sc.dragContentY);
            }
        }
        else {
            
            // Режим свободного перемещения контента.
            // Промотка списка ползунками:
            if (Utils.noeq(sc.scrollSetX, -1)) {
                sc.velocity.speed.x = 0;
                Utils.set(sc.contentX, -b.x - Math.max(0, b.width - outW) * sc.scrollSetX);
            }
            if (Utils.noeq(sc.scrollSetY, -1)) {
                sc.velocity.speed.y = 0;
                Utils.set(sc.contentY, -b.y - Math.max(0, b.height - outH) * sc.scrollSetY);
            }
            
            // Промотка списка колёсиком мыши по X:
            if (sc.wheelScrollX > 0) {
                sc.velocity.speed.x = 0;

                Utils.set(sc.contentX, sc.contentX + sc.wheelScrollX);
                if (sc.contentX > -b.x)
                    Utils.set(sc.contentX, -b.x);
            }
            else if (sc.wheelScrollX < 0) {
                sc.velocity.speed.x = 0;

                Utils.set(sc.contentX, sc.contentX + sc.wheelScrollX);
                if (sc.contentX < minX)
                    Utils.set(sc.contentX, minX);
            }

            // Промотка списка колёсиком мыши по Y:
            if (sc.wheelScrollY > 0) {
                sc.velocity.speed.y = 0;

                Utils.set(sc.contentY, sc.contentY + sc.wheelScrollY);
                if (sc.contentY > -b.y)
                    Utils.set(sc.contentY, -b.y);
            }
            else if (sc.wheelScrollY < 0) {
                sc.velocity.speed.y = 0;

                Utils.set(sc.contentY, sc.contentY + sc.wheelScrollY);
                if (sc.contentY < minY)
                    Utils.set(sc.contentY, minY);
            }

            // Скорость движения контента:
            if (sc.velocity.enabled && (Utils.noeq(sc.velocity.speed.x, 0) || Utils.noeq(sc.velocity.speed.y, 0))) {
                if (sc.velocity.speedDmp > 0) // <-- Затухание
                    sc.velocity.speed.mul(Math.max(0, 1 - sc.velocity.speedDmp * sc.theme.dt));
                
                if (sc.velocity.speedMax > 0 && sc.velocity.speed.len() > sc.velocity.speedMax) // <-- Максимум
                    sc.velocity.speed.nrm().mul(sc.velocity.speedMax);

                if (sc.velocity.speedMin > 0 && sc.velocity.speed.len() < sc.velocity.speedMin) // <-- Минимум
                    sc.velocity.speed.set(0, 0);
                else 
                    needUPD = true;

                Utils.set(sc.contentX, sc.contentX + sc.velocity.speed.x * sc.theme.dt);
                Utils.set(sc.contentY, sc.contentY + sc.velocity.speed.y * sc.theme.dt);
            }
            
            // Ограничение области перемещения контента по X:
            if (sc.contentX > -b.x) {
                if (sc.velocity.speed.x > 0) {
                    sc.velocity.speed.x = 0;
                    Utils.set(sc.contentX, -b.x);
                }
                else {
                    var dist = -b.x - sc.contentX;
                    if (dist < -1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        Utils.set(sc.contentX, sc.contentX + sc.contentBackSpeed * sc.theme.dt * dist);
                        if (sc.contentX <= -b.x)
                            Utils.set(sc.contentX, -b.x);
                        else
                            needUPD = true;
                    }
                    else {
                        Utils.set(sc.contentX, -b.x);
                    }
                }
            }
            else if (sc.contentX < minX) {
                if (sc.velocity.speed.x < 0) {
                    sc.velocity.speed.x = 0;
                    Utils.set(sc.contentX, minX);
                }
                else {
                    sc.velocity.speed.x = 0;
                    
                    var dist = minX - sc.contentX;
                    if (dist > 1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        Utils.set(sc.contentX, sc.contentX + sc.contentBackSpeed * sc.theme.dt * dist);
                        if (sc.contentX >= minX)
                            Utils.set(sc.contentX, minX);
                        else
                            needUPD = true;
                    }
                    else {
                        Utils.set(sc.contentX, minX);
                    }
                }
            }

            // Ограничение области перемещения контента по Y:
            if (sc.contentY > -b.y) {
                if (sc.velocity.speed.y > 0) {
                    sc.velocity.speed.y = 0;
                    Utils.set(sc.contentY, -b.y);
                }
                else {
                    var dist = -b.y - sc.contentY;
                    if (dist < -1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        Utils.set(sc.contentY, sc.contentY + sc.contentBackSpeed * sc.theme.dt * dist);
                        if (sc.contentY <= -b.y)
                            Utils.set(sc.contentY, -b.y);
                        else
                            needUPD = true;
                    }
                    else {
                        Utils.set(sc.contentY, -b.y);
                    }
                }
            }
            else if (sc.contentY < minY) {
                if (sc.velocity.speed.y < 0) {
                    sc.velocity.speed.y = 0;
                    Utils.set(sc.contentY, minY);
                }
                else {
                    sc.velocity.speed.y = 0;
                    
                    var dist = minY - sc.contentY;
                    if (dist > 1) { // <-- Минимальная дистанция для анимации возврата: 1px.
                        Utils.set(sc.contentY, sc.contentY + sc.contentBackSpeed * sc.theme.dt * dist);
                        if (sc.contentY >= minY)
                            Utils.set(sc.contentY, minY);
                        else
                            needUPD = true;
                    }
                    else {
                        Utils.set(sc.contentY,  minY);
                    }
                }
            }
        }
        sc.scrollSetX = -1;
        sc.scrollSetY = -1;
        sc.wheelScrollX = 0;
        sc.wheelScrollY = 0;

        // Позицианирование:
        sc.content.x = Math.round(sc.contentX);
        sc.content.y = Math.round(sc.contentY);

        // Маска:
        sc.contentMask.width = outW;
        sc.contentMask.height = outH;

        // Ползунки:
        sc.scrollIgnore = true;
        if (sh) {
            var v = b.width - outW;
            sc.scrollH.w = outW;
            sc.scrollH.y = outH;
            sc.scrollH.value = v>0?(-(sc.contentX + b.x) / v):0;
            sc.scrollH.thumbScale = outW / b.width;
            sc.scrollH.enabled = outW < b.width;

            Utils.show(sc, sc.scrollH);
        }
        else {
            Utils.hide(sc, sc.scrollH);
        }

        if (sv) {
            var v = b.height - outH;
            sc.scrollV.h = outH;
            sc.scrollV.x = outW;
            sc.scrollV.value = v>0?(-(sc.contentY + b.y) / v):0;
            sc.scrollV.thumbScale = outH / b.height;
            sc.scrollV.enabled = outH < b.height;

            Utils.show(sc, sc.scrollV);
        }
        else {
            Utils.hide(sc, sc.scrollV);
        }
        sc.scrollIgnore = false;

        // Анимация не завершена:
        if (needUPD)
            sc.updateNext(Component.UPDATE_SIZE);

        // События:
        if (Utils.noeq(evDrag, null)) {
            sc.emit(DragEvent.MOVE, evDrag);
            DragEvent.store(evDrag);
        }
        if (Utils.noeq(evDragOver, null)) {
            sc.emit(DragEvent.OVERDRAG, evDragOver);
            DragEvent.store(evDragOver);
        }
    }
}

/**
 * Параметры перетаскивания контента скроллера пальцем или курсором.
 */
typedef DragParams = 
{
    /**
     * Перетаскивание включено.
     * По умолчанию: `true` (Включено)
     */
    var enabled:Bool;

    /**
     * Параметры избыточного натяжения.
     * Не может быть `null`
     */
    var overdrag:OverdragParams;

    /**
     * Параметры инерции.
     * Не может быть `null`
     */
    var inertia:InertiaParams;
}

/**
 * Параметры избыточного натяжения.
 * Эти параметры влияют на то, как ведёт себя контент, когда он уже достиг предела
 * но его продлжают тянуть.
 */
typedef OverdragParams = 
{
    /**
     * Избыточное натяжение включено.
     * По умолчанию: `true`
     */
    var enabled:Bool;

    /**
     * Максимальная дистанция отдаления. (0-1)
     * 
     * Это значение указывает на то, как далеко может сместиться перетаскиваемый контент при
     * избыточном его натяжении. Значение 1 - соответствует ширине и высоте самого компонента,
     * для осей **x** и **y** соответственно.
     * 
     * По умолчанию: `0.5` (Контент можно дотянуть до середины компонента)
     */
    var distMax:Float;
}

/**
 * Параметры инерции.
 * Позволяет запускать содержимое списка в полёт при помощи резкого свапа.
 * Тут вы можете настроить параметры.
 */
typedef InertiaParams = 
{
    /**
     * Инерция включена.
     * По умолчанию: `true`
     */
    var enabled:Bool;

    /**
     * Интервал времени для расчёта свапа. (sec)
     * 
     * Этот промежуток времени используется для расчёта свапа.
     * Чем он больше, тем больше последних событий ввода будут
     * учавствовать в расчётах.
     * 
     * По умолчанию: `0.1`
     */
    var time:Float;

    /**
     * Множитель задаваемой скорости. (scale)
     * 
     * По умолчанию: `1` (100%)
     */
    var speed:Float;

    /**
     * Минимальная, пройденная дистанция для засчитывания свапа. (px)
     * 
     * По умолчанию: `50`
     */
    var dist:Float;
}

/**
 * Параметры движения контента скроллера.
 */
typedef VelocityParams = 
{
    /**
     * Движение включено.
     * Если `true`, то контент в скроллере может перемещаться автоматически при заданной ему скорости движения.
     * 
     * По умолчанию: `true` (Включено)
     */
    var enabled:Bool;

    /**
     * Скорость перемещения контента. (px/sec)
     * Этот вектор описывает текущую скорость и направление движения.
     * 
     * Не может быть `null`
     */
    var speed(default, null):Vec2;

    /**
     * Максимальная скорость движения контента. (px/sec)
     * 
     * По умолчанию: `0` (Не ограничено)
     */
    var speedMax:Float;

    /**
     * Минимальная скорость движения контента. (px/sec)
     * Скорость движения менее этого значения сбрасывается до `0`.
     * 
     * По умолчанию: `3`
     */
    var speedMin:Float;

    /**
     * Коэффициент торможения скорости движения контента. (scale/sec)
     * Это скалярное значение, в сколько раз уменьшится скорость за 1 секунду.
     * 
     * По умолчанию: `0.75`
     */
    var speedDmp:Float;
}

/**
 * Параметры ввода.
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