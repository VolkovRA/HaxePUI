package pui.window.controls;

import haxe.extern.EitherType;
import pixi.display.Container;
import pui.ui.Button;
import pui.ui.Component;
import pui.events.Event;

/**
 * Панелька с кнопками "ОК" и "Отмена" для запроса подтверждения пользователя.
 * 
 * Может использоваться для запроса подтверждения пользователя, предлагая
 * варианты ответа: "Да" или "Нет". (Есть и третий вариант - пользователь не ответил)
 * 
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class ControlConfirm extends Component
{
    /**
     * Тип компонента `ControlConfirm`.
     */
    static public inline var TYPE:String = "ControlConfirm";

    /**
     * Создать окно с сообщением.
     */
    public function new() {
        super();

        componentType = TYPE;

        buttonOK = new Button();
        buttonOK.text = "OK";
        buttonOK.on(Event.CLICK, onClickOK);

        buttonCancel = new Button();
        buttonCancel.text = "Cancel";
        buttonCancel.on(Event.CLICK, onClickCancel);

        Utils.set(updateLayers, ControlConfirm.defaultLayers);
        Utils.set(updateSize, ControlConfirm.defaultPositions);
    }

    private function onClickOK(e:Event):Void {
        result = true;
        if (parent != null && untyped parent.close != null)
            untyped parent.close();
    }

    private function onClickCancel(e:Event):Void {
        result = false;
        if (parent != null && untyped parent.close != null)
            untyped parent.close();
    }

    override function set_enabled(value:Bool):Bool {
        buttonOK.enabled = value;
        buttonCancel.enabled = value;
        return super.set_enabled(value);
    }

    /**
     * Кнопка "OK".
     * 
     * Не может быть `null`
     */
    public var buttonOK(default, null):Button;

    /**
     * Кнопка "Отмена".
     * 
     * Не может быть `null`
     */
    public var buttonCancel(default, null):Button;

    /**
     * Ответ пользователя.
     * - Содержит `true`, если пользователь нажал "Да".
     * - Содержит `false`, если пользователь нажал "Нет".
     * - Содержит `null`, если пользователь ещё не ответил.
     * 
     * По умолчанию: `null` (Пользователь пока не ответил)
     */
    public var result:Bool = null;

    /**
     * Выравнивание содержимого панели по оси X.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `AlignX.CENTER`.
     */
    public var alignX(default, set):AlignX = AlignX.CENTER;
    function set_alignX(value:AlignX):AlignX {
        if (Utils.eq(value, alignX))
            return value;

        alignX = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Выравнивание содержимого панели по оси Y.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `AlignY.CENTER`.
     */
    public var alignY(default, set):AlignY = AlignY.CENTER;
    function set_alignY(value:AlignY):AlignY {
        if (Utils.eq(value, alignY))
            return value;

        alignY = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ между кнопками. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`.
     */
    public var gap(default, set):Float = 0;
    function set_gap(value:Float):Float {
        if (Utils.eq(value, gap))
            return value;

        gap = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Выгрузить панельку.
     */
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        Utils.destroySkin(buttonOK, options);
        Utils.destroySkin(buttonCancel, options);
        super.destroy(options);
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Обычное положение слоёв.
     */
    static public var defaultLayers:LayersUpdater<ControlConfirm> = function(panel) {
        if (panel.enabled) {
            Utils.show(panel, panel.skinBg);
            Utils.hide(panel, panel.skinBgDisable);

            Utils.show(panel, panel.buttonOK);
            Utils.show(panel, panel.buttonCancel);
        }
        else {
            if (Utils.eq(panel.skinBgDisable, null)) {
                Utils.show(panel, panel.skinBg);
                //Utils.hide(panel, panel.skinBgDisable);
            }
            else {
                Utils.hide(panel, panel.skinBg);
                Utils.show(panel, panel.skinBgDisable);
            }

            Utils.show(panel, panel.buttonOK);
            Utils.show(panel, panel.buttonCancel);
        }
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Обычное выравнивание.
     */
    static public var defaultPositions:SizeUpdater<ControlConfirm> = function(panel) {
        Utils.size(panel.skinBg, panel.w, panel.h);
        Utils.size(panel.skinBgDisable, panel.w, panel.h);
        
        // Отступы:
        var pt:Float = 0;
        var pl:Float = 0;
        var pr:Float = 0;
        var pb:Float = 0;
        if (panel.padding != null) {
            if (panel.padding.top != null)      pt = panel.padding.top;
            if (panel.padding.left != null)     pl = panel.padding.left;
            if (panel.padding.right != null)    pr = panel.padding.right;
            if (panel.padding.bottom != null)   pb = panel.padding.bottom;
        }

        panel.buttonOK.update(true);
        panel.buttonCancel.update(true);

        if (panel.alignX == AlignX.LEFT) {
            panel.buttonOK.x = Math.round(pl);
            panel.buttonCancel.x = Math.round(panel.buttonOK.x + panel.buttonOK.w + panel.gap);
        }
        else if (panel.alignX == AlignX.CENTER){
            panel.buttonOK.x = Math.round(pl + (panel.w - panel.buttonOK.w - panel.buttonCancel.w - panel.gap) / 2);
            panel.buttonCancel.x = Math.round(panel.buttonOK.x + panel.buttonOK.w + panel.gap);
        }
        else {
            panel.buttonOK.x = Math.round(panel.w - panel.buttonOK.w - panel.buttonCancel.w - pr - panel.gap);
            panel.buttonCancel.x = Math.round(panel.buttonOK.x + panel.buttonOK.w + panel.gap);
        }

        if (panel.alignY == AlignY.TOP) {
            panel.buttonOK.y = Math.round(pt);
            panel.buttonCancel.y = panel.buttonOK.y;
        }
        else if (panel.alignY == AlignY.CENTER) {
            panel.buttonOK.y = Math.round(pt + (panel.h - panel.buttonOK.h) / 2);
            panel.buttonCancel.y = Math.round(pt + (panel.h - panel.buttonCancel.h) / 2);
        }
        else {
            panel.buttonOK.y = Math.round(panel.h - pb - panel.buttonOK.h);
            panel.buttonCancel.y = Math.round(panel.h - pb - panel.buttonCancel.h);
        }
    }
}