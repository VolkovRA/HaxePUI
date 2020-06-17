package pui.ui;

import pui.events.Event;
import pui.ui.Component;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import haxe.extern.EitherType;

/**
 * Прогресс бар.
 * 
 * @event Event.CHANGE              Диспетчерезируется при изменении значения: `ProgressBar.value`.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class ProgressBar extends Component
{
    /**
     * Тип компонента `ProgressBar`.
     */
    static public inline var TYPE:String = "ProgressBar";

    /**
     * Создать прогрессбар.
     */
     public function new() {
        super();
        
        this.componentType = TYPE;

        Utils.set(this.updateLayers, ProgressBar.defaultLayers);
        Utils.set(this.updateSize, ProgressBar.defaultSize);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Минимальное значение.
     * - Это значение не может быть больше `max`.
     * - Обновляет текущее значение `value`, если оно меньше нового `min`.
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
     * - Это значение не может быть меньше `min`.
     * - Обновляет текущее значение `value`, если оно больше нового `max`.
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
     * Поменять минимум и максимум на прогрессбаре местами.
     * 
     * По умолчанию: `false`
     */
    public var invert(default, set):Bool = false;
    function set_invert(value:Bool):Bool {
        if (Utils.eq(value, invert))
            return value;

        invert = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Значение прогрессбара.
     * - Это значение не может быть меньше `min`.
     * - Это значение не может быть больше `max`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`
     * 
     * @event Event.CHANGE  Посылается в случае установки **нового** значения.
     */
    public var value(default, set):Float = 0;
    function set_value(value2:Float):Float {
        var v = calcValue(value2);
        if (Utils.eq(v, value))
            return value2;

        value = v;
        update(false, Component.UPDATE_SIZE);
        Event.fire(Event.CHANGE, this);
        return value2;
    }

    /**
     * Ориентация прогрессбара.
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
     * Скин заливки.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinFill(default, set):Container = null;
    function set_skinFill(value:Container):Container {
        if (Utils.eq(value, skinFill))
            return value;

        Utils.hide(this, skinFill);
        skinFill = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заливки в выключенном состоянии.
     * Если значение не задано, используется `skinFill`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinFillDisable(default, set):Container = null;
    function set_skinFillDisable(value:Container):Container {
        if (Utils.eq(value, skinFillDisable))
            return value;

        Utils.hide(this, skinFillDisable);
        skinFillDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Получить новое значение для прогрессбара.
     * 
     * Получает на вход желаемое значение для прогрессбара и возварщает
     * соответствующее ему, корректное значение, с учётом всех проверок.
     * 
     * @param value Новое значение.
     * @return Обработанное значение прогрессбара.
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
     * Выгрузить прогрессбар.
	 */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        Utils.destroySkin(skinFill, options);
        Utils.destroySkin(skinFillDisable, options);

        super.destroy(options);
    }



    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв прогрессбара.
     */
    static public var defaultLayers:LayersUpdater<ProgressBar> = function(pr) {
        if (pr.enabled) {
            Utils.show(pr, pr.skinBg);
            Utils.hide(pr, pr.skinBgDisable);

            Utils.show(pr, pr.skinFill);
            Utils.hide(pr, pr.skinFillDisable);
        }
        else {
            if (Utils.eq(pr.skinBgDisable, null)) {
                Utils.show(pr, pr.skinBg);
                //Utils.hide(pr, pr.skinBgDisable);
            }
            else {
                Utils.hide(pr, pr.skinBg);
                Utils.show(pr, pr.skinBgDisable);
            }

            if (Utils.eq(pr.skinFillDisable, null)) {
                Utils.show(pr, pr.skinFill);
                //Utils.hide(pr, pr.skinFillDisable);
            }
            else {
                Utils.hide(pr, pr.skinFill);
                Utils.show(pr, pr.skinFillDisable);
            }
        }
    }

    /**
     * Обычное позицианирование прогрессбара.
     */
    static public var defaultSize:SizeUpdater<ProgressBar> = function(cp) {
        Utils.size(cp.skinBg, cp.w, cp.h);
        Utils.size(cp.skinBgDisable, cp.w, cp.h);

        // Отступы:
        var pt:Float = 0;
        var pr:Float = 0;
        var pl:Float = 0;
        var pb:Float = 0;
        if (cp.padding != null) {
            if (cp.padding.top != null)     pt = cp.padding.top;
            if (cp.padding.left != null)    pl = cp.padding.left;
            if (cp.padding.right != null)   pr = cp.padding.right;
            if (cp.padding.bottom != null)  pb = cp.padding.bottom;
        }

        var ow = Math.max(0, cp.w - pl - pr);
        var oh = Math.max(0, cp.h - pt - pb);
        var d = cp.max - cp.min;
        var v = d>0?((cp.value - cp.min) / d):0;

        // Позицианирование шкур:
        if (Utils.eq(cp.orientation, Orientation.VERTICAL)) {
            var size = Math.round(v * oh);
            if (cp.invert) {
                if (cp.skinFill != null) {
                    cp.skinFill.x = pl;
                    cp.skinFill.y = pt;
                    cp.skinFill.width = ow;
                    cp.skinFill.height = size;
                }
                if (cp.skinFillDisable != null) {
                    cp.skinFillDisable.x = pl;
                    cp.skinFillDisable.y = pt;
                    cp.skinFillDisable.width = ow;
                    cp.skinFillDisable.height = size;
                }
            }
            else {
                if (cp.skinFill != null) {
                    if (cp.skinFill != null) {
                        cp.skinFill.x = pl;
                        cp.skinFill.y = pt + (oh-size);
                        cp.skinFill.width = ow;
                        cp.skinFill.height = size;
                    }
                    if (cp.skinFillDisable != null) {
                        cp.skinFillDisable.x = pl;
                        cp.skinFillDisable.y = pt + (oh-size);
                        cp.skinFillDisable.width = ow;
                        cp.skinFillDisable.height = size;
                    }
                }
            }
        }
        else {
            var size = Math.round(v * ow);
            if (cp.invert) {
                if (cp.skinFill != null) {
                    cp.skinFill.x = cp.w - size - pr;
                    cp.skinFill.y = pt;
                    cp.skinFill.width = size;
                    cp.skinFill.height = oh;
                }
                if (cp.skinFillDisable != null) {
                    cp.skinFillDisable.x = cp.w - size - pr;
                    cp.skinFillDisable.y = pt;
                    cp.skinFillDisable.width = size;
                    cp.skinFillDisable.height = oh;
                }
            }
            else {
                if (cp.skinFill != null) {
                    if (cp.skinFill != null) {
                        cp.skinFill.x = pl;
                        cp.skinFill.y = pt;
                        cp.skinFill.width = size;
                        cp.skinFill.height = oh;
                    }
                    if (cp.skinFillDisable != null) {
                        cp.skinFillDisable.x = pl;
                        cp.skinFillDisable.y = pt;
                        cp.skinFillDisable.width = size;
                        cp.skinFillDisable.height = oh;
                    }
                }
            }
        }
    }
}