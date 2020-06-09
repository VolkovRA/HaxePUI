package pui.ui;

import pui.events.Event;
import pui.dom.PointerType;
import pui.ui.Component;
import pui.pixi.PixiEvent;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.math.Point;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

/**
 * Полоса прокрутки.
 * 
 * События:
 * - `Event.CHANGE`             Диспетчерезируется при изменении значения: `ScrollBar.value`.
 * - `ComponentEvent.UPDATE`    Обновление компонента. (Перерисовка)
 * - *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class ScrollBar extends Component
{
    /**
     * Тип компонента `ScrollBar`.
     */
    static public inline var TYPE:String = "ScrollBar";

    /**
     * Кешированный `Point`.
     * Используется для повторных вычислений внутри компонента.
     */
    static private var POINT:Point = new Point(0, 0);

    /**
     * Кешированный `Padding`.
     * Используется для повторных вычислений внутри компонента.
     */
    static private var PADDING:Offset = { top:0, left:0, right:0, bottom:0 };

    // Приват
    private var isDragging:Bool = false;
    private var dragX:Float = 0;
    private var dragY:Float = 0;

    /**
     * Создать скроллбар.
     */
    public function new() {
        super(TYPE);

        Utils.set(this.updateLayers, ScrollBar.defaultLayers);
        Utils.set(this.updateSize, ScrollBar.defaultSize);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onThumbDown(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;
        
        thumb.on(PixiEvent.POINTER_MOVE, onThumbMove);
        isDragging = true;

        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        thumb.toLocal(POINT, null, POINT);
        dragX = POINT.x;
        dragY = POINT.y;
    }

    private function onThumbMove(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;

        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        toLocal(POINT, null, POINT);

        // Отступы:
        var p = PADDING;
        if (Utils.noeq(padding, null))
            p = padding;

        // Перетаскивание:
        if (Utils.eq(orientation, Orientation.HORIZONTAL)) { // Горизонтальный
            var dx:Float = POINT.x - dragX;
            var fx:Float = p.left;
            var fw:Float = w - p.left - p.right;

            if (Utils.noeq(decBt, null)) {
                fx += decBt.w;
                fw -= decBt.w;
            }
            if (Utils.noeq(incBt, null)) {
                fw -= incBt.w;
            }

            // Тип ползунка:
            if (pointMode) {
                thumb.y = Math.round(p.top + (h - p.top - p.bottom) / 2);
            }
            else {
                fw -= thumb.w;
                thumb.y = Math.round(p.top);
            }

            // Позиция ползунка:
            if (fw > 0) { // Исключаем деление на ноль
                if (dx < fx)
                    thumb.x = Math.round(fx);
                else if (dx > fx + fw)
                    thumb.x = Math.round(fx + fw);
                else 
                    thumb.x = Math.round(dx);

                value = ((thumb.x - fx) / fw) * (max - min) + min;
            }
            else {
                thumb.x = Math.round(fx);
                value = min;
            }
        }
        else { // Вертикальный
            var dy:Float = POINT.y - dragY;
            var fy:Float = p.top;
            var fh:Float = h - p.top - p.bottom;

            if (Utils.noeq(decBt, null)) {
                fy += decBt.h;
                fh -= decBt.h;
            }
            if (Utils.noeq(incBt, null)) {
                fh -= incBt.h;
            }

            // Тип ползунка:
            if (pointMode) {
                thumb.x = Math.round(p.left + (w - p.left - p.right) / 2);
            }
            else {
                fh -= thumb.h;
                thumb.x = Math.round(p.left);
            }

            // Позиция ползунка:
            if (fh > 0) { // Исключаем деление на ноль
                if (dy < fy)
                    thumb.y = Math.round(fy);
                else if (dy > fy + fh)
                    thumb.y = Math.round(fy + fh);
                else 
                    thumb.y = Math.round(dy);

                value = ((thumb.y - fy) / fh) * (max - min) + min;
            }
            else {
                thumb.y = Math.round(fy);
                value = min;
            }
        }
    }

    private function onThumbUp(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        thumb.off(PixiEvent.POINTER_MOVE, onThumbMove);
        isDragging = false;
        update(false, Component.UPDATE_SIZE); // <-- Update Thumb
    }

    private function onDecPress(e:Event):Void {
        value -= step;
    }

    private function onIncPress(e:Event):Void {
        value += step;
    }

    private function onBgDown(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        skinScroll.on(PixiEvent.POINTER_MOVE, onBgMove);
        onBgMove(e);
    }

    private function onBgUp(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        skinScroll.off(PixiEvent.POINTER_MOVE, onBgMove);
    }

    private function onBgMove(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;

        POINT.x = e.data.global.x;
        POINT.y = e.data.global.y;
        toLocal(POINT, null, POINT);

        if (Utils.eq(orientation, Orientation.HORIZONTAL)) {
            var fx:Float = 0;
            var fw:Float = w;
            if (Utils.noeq(padding, null)) {
                fx += padding.left;
                fw -= padding.left + padding.right;
            }
            if (Utils.noeq(decBt, null)) {
                fx += decBt.w;
                fw -= decBt.w;
            }
            if (Utils.noeq(incBt, null)) {
                fw -= incBt.w;
            }

            // Активность только в рамах скроллбара:
            if (fw > 0 && POINT.x >= fx && POINT.x <= fx + fw && POINT.y >= 0 && POINT.y <= h) {
                if (!pointMode && thumb != null && POINT.x >= thumb.x && POINT.x <= thumb.x + thumb.w && POINT.y >= thumb.y && POINT.y <= thumb.y + thumb.h)
                    return;

                value = ((POINT.x - fx) / fw) * (max - min) + min;
            }
            else {
                skinScroll.off(PixiEvent.POINTER_MOVE, onBgMove);
            }
        }
        else {
            var fy:Float = 0;
            var fh:Float = h;
            if (Utils.noeq(padding, null)) {
                fy += padding.top;
                fh -= padding.top + padding.bottom;
            }
            if (Utils.noeq(decBt, null)) {
                fy += decBt.h;
                fh -= decBt.h;
            }
            if (Utils.noeq(incBt, null)) {
                fh -= incBt.h;
            }

            // Активность только в рамах скроллбара:
            if (fh > 0 && POINT.y >= fy && POINT.y <= fy + fh && POINT.x >= 0 && POINT.x <= w) {
                if (!pointMode && thumb != null && POINT.y >= thumb.y && POINT.y <= thumb.y + thumb.h && POINT.x >= thumb.x && POINT.x <= thumb.x + thumb.w)
                    return;

                value = ((POINT.y - fy) / fh) * (max - min) + min;
            }
            else {
                skinScroll.off(PixiEvent.POINTER_MOVE, onBgMove);
            }
        }
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        if (Utils.noeq(incBt, null)) incBt.enabled = value;
        if (Utils.noeq(decBt, null)) decBt.enabled = value;
        if (Utils.noeq(thumb, null)) thumb.enabled = value;
        return super.set_enabled(value);
    }

    /**
     * Минимальное значение.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`
     */
    public var min(default, set):Float = 0;
    function set_min(value2:Float):Float {
        var v = value2>max?max:value2;
        if (Utils.eq(v, min))
            return value2;

        min = v;
        update(false, Component.UPDATE_SIZE);
        value = value; // Update
        return value2;
    }

    /**
     * Максимальное значение.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `1`
     */
    public var max(default, set):Float = 1;
    function set_max(value2:Float):Float {
        var v = value2<min?min:value2;
        if (Utils.eq(v, max))
            return value2;

        max = v;
        update(false, Component.UPDATE_SIZE);
        value = value; // Update
        return value2;
    }

    /**
     * Значение скроллбара.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`
     */
    public var value(default, set):Float = 0;
    function set_value(value2:Float):Float {
        var v = calcValue(value2);
        
        if (Utils.eq(v, value))
            return value2;

        value = v;
        update(false, Component.UPDATE_SIZE);

        var e = Event.get(Event.CHANGE, this);
        emit(Event.CHANGE, e);
        Event.store(e);

        return value2;
    }

    /**
     * Смещение значения при нажатии кнопок: `incBt` и `decBt`.
     * 
     * По умолчанию: `0.02`
     */
    public var step:Float = 0.02;

    /**
     * Ориентация полосы прокрутки.
     * 
     * Позволяет задать горизонтыльную или вертикальную ориентацию.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `Orientation.HORIZONTAL`
     */
    public var orientation(default, set):Orientation = Orientation.HORIZONTAL;
    function set_orientation(value:Orientation):Orientation {
        if (Utils.eq(value, orientation))
            return value;

        orientation = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Кнопка уменьшения.
     * 
     * Позволяет задать кнопку для уменьшения значения ползунка.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null` (Без кнопки)
     */
    public var decBt(default, set):Button = null;
    function set_decBt(value:Button):Button {
        if (Utils.eq(value, decBt))
            return value;

        if (Utils.noeq(decBt, null)) {
            Utils.hide(this, decBt);
            decBt.off(Event.PRESS, onDecPress);
        }

        decBt = value;

        if (Utils.noeq(decBt, null)) {
            decBt.on(Event.PRESS, onDecPress);
        }

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Кнопка увеличения.
     * 
     * Позволяет задать кнопку для увеличения значения ползунка.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null` (Без кнопки)
     */
    public var incBt(default, set):Button = null;
    function set_incBt(value:Button):Button {
        if (Utils.eq(value, incBt))
            return value;

        if (Utils.noeq(incBt, null)) {
            Utils.hide(this, incBt);
            incBt.off(Event.PRESS, onIncPress);
        }
        
        incBt = value;

        if (Utils.noeq(incBt, null)) {
            incBt.on(Event.PRESS, onIncPress);
        }

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Кнопка ползунка.
     * 
     * Позволяет задать кнопку ползунка скроллера.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null` (Без кнопки)
     */
    public var thumb(default, set):Button = null;
    function set_thumb(value:Button):Button {
        if (Utils.eq(value, thumb))
            return value;

        if (Utils.noeq(thumb, null)) {
            Utils.hide(this, thumb);

            thumb.off(PixiEvent.POINTER_DOWN, onThumbDown);
            thumb.off(PixiEvent.POINTER_MOVE, onThumbMove);
            thumb.off(PixiEvent.POINTER_UP, onThumbUp);
            thumb.off(PixiEvent.POINTER_UP_OUTSIDE, onThumbUp);
        }

        thumb = value;
        isDragging = false;

        if (Utils.noeq(thumb, null)) {
            thumb.on(PixiEvent.POINTER_DOWN, onThumbDown);
            thumb.on(PixiEvent.POINTER_UP, onThumbUp);
            thumb.on(PixiEvent.POINTER_UP_OUTSIDE, onThumbUp);
        }

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Режим точечного ползунка скроллбара.
     * - Если `true` - Кнопка скролла не растягивается. Удобно для ползунка в виде точки.
     * - Если `false` - Кнопка скролла растягивается. (По умолчанию)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `false`
     */
    public var pointMode(default, set):Bool = false;
    function set_pointMode(value:Bool):Bool {
        if (Utils.eq(value, pointMode))
            return value;

        pointMode = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Размер ползунка. (0-1)
     * 
     * Позволяет регулировать размеры ползунка скроллбара. Это может быть удобно, например,
     * для обозначения размера прокручиваемой области.
     * 
     * - Это значение работает только при выключенном: `pointMode=false`.
     * - Это значение не может быть меньше `0` или больше `1`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0.25` (25% От исходного размера ползунка)
     */
    public var thumbScale(default, set):Float = 0.25;
    function set_thumbScale(value:Float):Float {
        var v:Float = 0;
        if (value > 1)
            v = 1;
        else if (value > 0)
            v = value;

        if (Utils.eq(v, thumbScale))
            return value;

        thumbScale = v;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Фон скроллера.
     * 
     * Этот фон отличается от `skinBg` тем, что не подкладывается под кнопки: `incBt` и `decBt`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null`
     */
    public var skinScroll(default, set):Container = null;
    function set_skinScroll(value:Container):Container {
        if (Utils.eq(value, skinScroll))
            return value;

        if (Utils.noeq(skinScroll, null)) {
            Utils.hide(this, skinScroll);
            skinScroll.off(PixiEvent.POINTER_DOWN, onBgDown);
            skinScroll.off(PixiEvent.POINTER_MOVE, onBgMove);
            skinScroll.off(PixiEvent.POINTER_UP, onBgUp);
            skinScroll.off(PixiEvent.POINTER_UP_OUTSIDE, onBgUp);
        }

        skinScroll = value;

        if (Utils.noeq(skinScroll, null)) {
            skinScroll.on(PixiEvent.POINTER_DOWN, onBgDown);
            skinScroll.on(PixiEvent.POINTER_UP, onBgUp);
            skinScroll.on(PixiEvent.POINTER_UP_OUTSIDE, onBgUp);
        }

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Фон скроллера в выключенном состоянии.
     * Если значение не задано, используется `skinScroll`.
     * 
     * Этот фон отличается от `skinBg` тем, что не подкладывается под кнопки: `incBt` и `decBt`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторной перерисовки.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null`
     */
    public var skinScrollDisable(default, set):Container = null;
    function set_skinScrollDisable(value:Container):Container {
        if (Utils.eq(value, skinScrollDisable))
            return value;

        Utils.hide(this, skinScrollDisable);
        skinScrollDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Получить новое значение для скроллбара.
     * 
     * Получает на вход желаемое значение для скроллбара и возварщает
     * соответствующее ему, корректное значение, с учётом всех проверок.
     * 
     * @param value Новое значение.
     * @return Обработанное значение скроллбара.
     */
    private function calcValue(value:Float):Float {
        if (value == null || Math.isNaN(value))
            return 0;
        if (value > max)
            return max;
        if (value < min)
            return min;
        
        return value;
    }

    /**
     * Выгрузить скроллбар.
	 */
     override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        if (Utils.noeq(incBt, null)) {
            incBt.destroy(options);
            Utils.delete(incBt);
        }
        if (Utils.noeq(decBt, null)) {
            decBt.destroy(options);
            Utils.delete(decBt);
        }
        if (Utils.noeq(thumb, null)) {
            thumb.destroy(options);
            Utils.delete(thumb);
        }
        if (Utils.noeq(skinScroll, null)) {
            skinScroll.destroy(options);
            Utils.delete(skinScroll);
        }
        if (Utils.noeq(skinScrollDisable, null)) {
            skinScrollDisable.destroy(options);
            Utils.delete(skinScrollDisable);
        }

        isDragging = false;

        super.destroy(options);
    }


    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв скроллбара.
     */
    static public var defaultLayers:LayersUpdater<ScrollBar> = function(scroll) {
        if (scroll.enabled) {
            Utils.show(scroll, scroll.skinBg);
            Utils.hide(scroll, scroll.skinBgDisable);

            Utils.show(scroll, scroll.skinScroll);
            Utils.hide(scroll, scroll.skinScrollDisable);

            Utils.show(scroll, scroll.decBt);
            Utils.show(scroll, scroll.incBt);
            Utils.show(scroll, scroll.thumb);
        }
        else {
            if (Utils.eq(scroll.skinBgDisable, null)) {
                Utils.show(scroll, scroll.skinBg);
                //Utils.hide(scroll, scroll.skinBgDisable);
            }
            else {
                Utils.hide(scroll, scroll.skinBg);
                Utils.show(scroll, scroll.skinBgDisable);
            }

            if (Utils.eq(scroll.skinScrollDisable, null)) {
                Utils.show(scroll, scroll.skinScroll);
                //Utils.hide(scroll, scroll.skinScrollDisable);
            }
            else {
                Utils.hide(scroll, scroll.skinScroll);
                Utils.show(scroll, scroll.skinScrollDisable);
            }

            Utils.show(scroll, scroll.decBt);
            Utils.show(scroll, scroll.incBt);
            Utils.show(scroll, scroll.thumb);
        }
    }

    /**
     * Обычное позицианирование скроллбара.
     */
    static public var defaultSize:SizeUpdater<ScrollBar> = function(sc) {
        Utils.size(sc.skinBg, sc.w, sc.h);
        Utils.size(sc.skinBgDisable, sc.w, sc.h);

        // Отступы:
        var p = PADDING;
        if (Utils.noeq(sc.padding, null))
            p = sc.padding;

        // Позицианирование:
        if (Utils.eq(sc.orientation, Orientation.HORIZONTAL)) { // Горизонтальный
            var fx:Float = 0;
            var fw:Float = sc.w;

            // Кнопки:
            if (Utils.noeq(sc.decBt, null)) {
                sc.decBt.x = 0;
                sc.decBt.y = 0;
                sc.decBt.h = sc.h;
                sc.decBt.update(true);
                
                fx += sc.decBt.w;
                fw -= sc.decBt.w;
            }
            if (Utils.noeq(sc.incBt, null)) {
                sc.incBt.update(true);
                sc.incBt.x = Math.round(sc.w - sc.incBt.w);
                sc.incBt.y = 0;
                sc.incBt.h = sc.h;
                fw -= sc.incBt.w;
            }

            // Фоны:
            if (Utils.noeq(sc.skinScroll, null)) {
                sc.skinScroll.x = Math.round(fx);
                sc.skinScroll.y = 0;
                sc.skinScroll.width = Math.round(fw);
                sc.skinScroll.height = sc.h;
            }
            if (Utils.noeq(sc.skinScrollDisable, null)) {
                sc.skinScrollDisable.x = Math.round(fx);
                sc.skinScrollDisable.y = 0;
                sc.skinScrollDisable.width = Math.round(fw);
                sc.skinScrollDisable.height = sc.h;
            }
            
            if (Utils.eq(sc.thumb, null))
                return;

            fx += p.left;
            fw -= p.left + p.right;

            if (fw < 0)
                fw = 0;
            
            // Ползунок:
            if (sc.pointMode) {
                if (!sc.isDragging) {
                    sc.thumb.y = Math.round(p.top + (Math.max(0, sc.h - p.top - p.bottom) / 2));

                    var v = sc.max - sc.min;
                    if (v > 0) // Исключаем деление на ноль
                        sc.thumb.x = Math.round(fx + fw * (((sc.value - sc.min) / v)));
                    else 
                        sc.thumb.x = Math.round(fx);
                }
            }
            else {
                sc.thumb.w = Math.max(3, Math.round(fw * sc.thumbScale)); // 3px min size
                sc.thumb.h = Math.max(1, Math.round(sc.h - p.top - p.bottom));
                sc.thumb.update(true);

                if (!sc.isDragging) {
                    sc.thumb.y = Math.round(p.top);

                    var v = sc.max - sc.min;
                    if (v > 0) // Исключаем деление на ноль
                        sc.thumb.x = Math.round(fx + Math.max(0, fw - sc.thumb.w) * ((sc.value - sc.min) / v));
                    else
                        sc.thumb.x = Math.round(fx);
                }
            }
        }
        else { // Вертикальный
            var fy:Float = 0;
            var fh:Float = sc.h;

            // Кнопки:
            if (Utils.noeq(sc.decBt, null)) {
                sc.decBt.x = 0;
                sc.decBt.y = 0;
                sc.decBt.w = sc.w;
                sc.decBt.update(true);
                
                fy += sc.decBt.h;
                fh -= sc.decBt.h;
            }
            if (Utils.noeq(sc.incBt, null)) {
                sc.incBt.update(true);
                sc.incBt.x = 0;
                sc.incBt.y = Math.round(sc.h - sc.incBt.h);
                sc.incBt.w = sc.w;
                fh -= sc.incBt.h;
            }

            // Фоны:
            if (Utils.noeq(sc.skinScroll, null)) {
                sc.skinScroll.x = 0;
                sc.skinScroll.y = Math.round(fy);
                sc.skinScroll.width = sc.w;
                sc.skinScroll.height = Math.round(fh);
            }
            if (Utils.noeq(sc.skinScrollDisable, null)) {
                sc.skinScrollDisable.x = 0;
                sc.skinScrollDisable.y = Math.round(fy);
                sc.skinScrollDisable.width = sc.w;
                sc.skinScrollDisable.height = Math.round(fh);
            }
            
            if (Utils.eq(sc.thumb, null))
                return;

            fy += p.top;
            fh -= p.top + p.bottom;

            if (fh < 0)
                fh = 0;
            
            // Ползунок:
            if (sc.pointMode) {
                if (!sc.isDragging) {
                    sc.thumb.x = Math.round(p.left + (Math.max(0, sc.w - p.left - p.right) / 2));

                    var v = sc.max - sc.min;
                    if (v > 0) // Исключаем деление на ноль
                        sc.thumb.y = Math.round(fy + fh * (((sc.value - sc.min) / v)));
                    else 
                        sc.thumb.y = Math.round(fy);
                }
            }
            else {
                sc.thumb.w = Math.max(1, Math.round(sc.w - p.left - p.right));
                sc.thumb.h = Math.max(3, Math.round(fh * sc.thumbScale)); // 3px min size
                sc.thumb.update(true);

                if (!sc.isDragging) {
                    sc.thumb.x = Math.round(p.left);

                    var v = sc.max - sc.min;
                    if (v > 0) // Исключаем деление на ноль
                        sc.thumb.y = Math.round(fy + Math.max(0, fh - sc.thumb.h) * ((sc.value - sc.min) / v));
                    else
                        sc.thumb.y = Math.round(fy);
                }
            }
        }
    }
}