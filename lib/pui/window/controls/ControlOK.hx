package pui.window.controls;

import haxe.extern.EitherType;
import pixi.display.Container;
import pui.ui.Button;
import pui.ui.Component;
import pui.events.Event;

/**
 * Панелька с кнопкой ОК.
 * 
 * Идеально для окошка с уведомлением для закрытия окна! Компонент содержит
 * одну единственную кнопку, при нажатии на которую вызывается метод `close()`
 * родительского объекта. (Если есть)
 * 
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class ControlOK extends Component
{
    /**
     * Тип компонента `ControlOK`.
     */
    static public inline var TYPE:String = "ControlOK";

    /**
     * Создать окно с сообщением.
     */
    public function new() {
        super();

        componentType = TYPE;

        buttonOK = new Button();
        buttonOK.text = "OK";
        buttonOK.on(Event.CLICK, onClickOK);

        Utils.set(updateLayers, ControlOK.defaultLayers);
        Utils.set(updateSize, ControlOK.defaultPositions);
    }

    private function onClickOK(e:Event):Void {
        if (parent != null && untyped parent.close != null)
            untyped parent.close();
    }

    override function set_enabled(value:Bool):Bool {
        buttonOK.enabled = value;
        return super.set_enabled(value);
    }

    /**
     * Кнопка OK.
     * 
     * Не может быть `null`
     */
    public var buttonOK(default, null):Button;

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
     * Выгрузить панельку.
     */
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        Utils.destroySkin(buttonOK, options);
        super.destroy(options);
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Обычное положение слоёв.
     */
    static public var defaultLayers:LayersUpdater<ControlOK> = function(panel) {
        if (panel.enabled) {
            Utils.show(panel, panel.skinBg);
            Utils.hide(panel, panel.skinBgDisable);

            Utils.show(panel, panel.buttonOK);
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
        }
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Обычное выравнивание.
     */
    static public var defaultPositions:SizeUpdater<ControlOK> = function(panel) {
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
        if (panel.alignX == AlignX.LEFT)
            panel.buttonOK.x = Math.round(pl);
        else if (panel.alignX == AlignX.CENTER)
            panel.buttonOK.x = Math.round(pl + (panel.w - panel.buttonOK.w) / 2);
        else
            panel.buttonOK.x = Math.round(panel.w - pr - panel.buttonOK.w);

        if (panel.alignY == AlignY.TOP)
            panel.buttonOK.y = Math.round(pt);
        else if (panel.alignY == AlignY.CENTER)
            panel.buttonOK.y = Math.round(pt + (panel.h - panel.buttonOK.h) / 2);
        else
            panel.buttonOK.y = Math.round(panel.h - pb - panel.buttonOK.h);
    }
}