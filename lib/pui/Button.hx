package pui;

import pui.Component;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;



/**
 * Кнопка.
 * Содержит содержать текст и/или иконку.
 * 
 * `События:`
 * ------------
 * - `UIEvent.CLICK`                Клик по кнопке. Не путайте с `Event.CLICK`.
 *                                  Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 *                                  `Button->Void`
 * * `UIEvent.DOUBLE_CLICK`         Двойной клик по кнопке.
 *                                  Это событие не диспетчерезируется, если кнопка была выключена `enabled=false`: `Button->Void`. 
 * * `UIEvent.STATE` - Состояние кнопки изменено: `Button->ButtonState->Void`. (Передаёт старое состояние)
 * * `UIEvent.UPDATE` - Кнопка обновилась: `Button->changes->Void`. (Передаёт старые изменения)
 * * *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class Button extends Component
{
    /**
     * Тип компонента `Button`.
     */
    static public inline var TYPE:String = "Button";

    /**
     * Создать кнопку.
     * @param text Отображаемый текст.
     */
    public function new(text:String = "") {
        super(TYPE);
        
        this.text = text;
        this.buttonMode = true;
        this.interactive = true;

        Utils.set(this.updateLayers, Button.updateLayersIcoDown);
        Utils.set(this.updateSize, Button.updateSizeIcoML);
        Utils.addDoubleClick(this);

        on(UIEvent.DOUBLE_CLICK, function(){ trace("DOUBLE TAP"); });

        label.on(UIEvent.UPDATE, onLabelUpdated);

        /*
        on(Event.POINTER_OVER, onRollOver);
        on(Event.POINTER_OUT, onRollOut);
        on(Event.POINTER_DOWN, onDown);
        on(Event.POINTER_UP, onUp);
        on(Event.POINTER_UP_OUTSIDE, onUpOutside);
        */
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onClick() {
        
    }
    private function onRollOver(e:InteractionEvent):Void {
        if (isPrimary && !e.data.isPrimary)
            return;

        if (downCurrentButton && Utils.flagsOR(buttons, e.data.buttons)) // 1 - Левая кнопка мыши
            state = ButtonState.PRESS;
        else
            state = ButtonState.HOVER;
    }
    private function onRollOut(e:InteractionEvent):Void {
        if (isPrimary && !e.data.isPrimary)
            return;

        state = ButtonState.NORMAL;
    }
    private function onDown(e:InteractionEvent):Void {
        if (isPrimary && !e.data.isPrimary)
            return;

        

        downCurrentButton = true;
        state = ButtonState.PRESS;
    }
    private function onUp(e:InteractionEvent):Void {
        if (isPrimary && !e.data.isPrimary)
            return;

        downCurrentButton = false;
        state = ButtonState.HOVER;
    }
    private function onUpOutside(e:InteractionEvent):Void {
        if (isPrimary && !e.data.isPrimary)
            return;

        downCurrentButton = false;
        state = ButtonState.NORMAL;
    }
    private function onLabelUpdated():Void {
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Использовать только основное устройство ввода.
     * 
     * Основное устройство - это мышь, первое касание на сенсорном устройстве или т.п.
     *   - Если задано `true` - кнопка будет реагировать только на ввод с основного устройства.
     *   - Если задано `false` - кнопка будет реагировать на ввод с любого устройства.
     * 
     * По умолчанию: `true`
     * 
     * @see PointerEvent.isPrimary: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/isPrimary
     */
    public var isPrimary:Bool = true;

    /**
     * Маска клавиш реагирования.
     * 
     * Используется для контроля клавиш, которыми может осуществляться взаимодействие с кнопкой.
     * По умолчанию кнопка реагирует только на нажатие левой кнопкой мыши.
     * Вы можете добавить реагирование и на правую кнопку следующим образом:
     * ```
     * button.buttons = MouseButtons.LEFT | MouseButtons.RIGHT; // Реагирует на правую и на левую кнопки мыши
     * ```
     * 
     * По умолчанию: `MouseButtons.LEFT`
     */
    public var buttons:BitMask = MouseButtons.LEFT;

    /**
     * Флаг активного нажатия.
     * Используется кнопкой, чтобы определить, нажали изначально по ней или нет.
     */
    private var downCurrentButton:Bool = false;

    /**
     * Текстовая метка на кнопке.
     * Не может быть `null`.
     */
    public var label(default, null):Label = new Label();

    /**
     * Текст на кнопке.
     * Синоним для: `label.text`.
     */
    public var text(get, set):String;
    inline function get_text():String {
        return label.text;
    }
    inline function set_text(value:String):String {
        label.text = value;
        return value;
    }

    /**
     * Состояние кнопки.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для переключения скинов состояния.
     * 
     * По умолчанию: `ButtonState.NORMAL`
     */
    public var state(default, set):ButtonState = ButtonState.NORMAL;
    function set_state(value:ButtonState):ButtonState {
        if (Utils.eq(value, state))
            return value;

        var olds = state;
        state = value;
        update(false, Component.UPDATE_LAYERS);
        emit(UIEvent.STATE, this, olds);
        return value;
    }

    /**
     * Иконка на кнопке.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var ico(default, set):Container = null;
    function set_ico(value:Container):Container {
        if (Utils.eq(value, ico))
            return value;

        Utils.hide(this, ico);
        ico = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Иконка на кнопке при наведении курсора.
     * Если значение не задано, используется `ico`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoHover(default, set):Container = null;
    function set_icoHover(value:Container):Container {
        if (Utils.eq(value, icoHover))
            return value;

        Utils.hide(this, icoHover);
        icoHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Иконка на кнопке при нажатии.
     * Если значение не задано, используется `ico`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoPress(default, set):Container = null;
    function set_icoPress(value:Container):Container {
        if (Utils.eq(value, icoPress))
            return value;

        Utils.hide(this, icoPress);
        icoPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при наведении курсора.
     * Если значение не задано, используется `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для позицианирования скина.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgHover(default, set):Container = null;
    function set_skinBgHover(value:Container):Container {
        if (Utils.eq(value, skinBgHover))
            return value;

        Utils.hide(this, skinBgHover);
        skinBgHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при нажатии.
     * Если значение не задано, используется `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для позицианирования скина.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgPress(default, set):Container = null;
    function set_skinBgPress(value:Container):Container {
        if (Utils.eq(value, skinBgPress))
            return value;

        Utils.hide(this, skinBgPress);
        skinBgPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Выгрузить кнопку.
	 */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        if (Utils.noeq(label, null)) {
            label.destroy(options);
            Utils.delete(label);
        }
        if (Utils.noeq(skinBgHover, null)) {
            skinBgHover.destroy(options);
            Utils.delete(skinBgHover);
        } 
        if (Utils.noeq(skinBgPress, null)) {
            skinBgPress.destroy(options);
            Utils.delete(skinBgPress);
        }
        if (Utils.noeq(ico, null)) {
            ico.destroy(options);
            Utils.delete(ico);
        } 
        if (Utils.noeq(icoHover, null)) {
            icoHover.destroy(options);
            Utils.delete(icoHover);
        }
        if (Utils.noeq(icoPress, null)) {
            icoPress.destroy(options);
            Utils.delete(icoPress);
        }

        super.destroy(options);
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Иконка над текстом.
     */
    static public var updateLayersIcoTop:SizeUpdater<Button> = function(bt) {
        if (Utils.eq(bt.state, ButtonState.HOVER)) {
            if (Utils.eq(bt.skinBgHover, null)) {
                Utils.show(bt, bt.skinBg);
                //Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.show(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
            }

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);

            if (Utils.eq(bt.icoHover, null)) {
                Utils.show(bt, bt.ico);
                //Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.show(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
            }
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) {
            if (Utils.eq(bt.skinBgPress, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                //Utils.hide(bt, bt.skinBgPress);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.show(bt, bt.skinBgPress);
            }

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);

            if (Utils.eq(bt.icoPress, null)) {
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                //Utils.hide(bt, bt.icoPress);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.show(bt, bt.icoPress);
            }
        }
        else { // NORMAL
            Utils.show(bt, bt.skinBg);
            Utils.hide(bt, bt.skinBgHover);
            Utils.hide(bt, bt.skinBgPress);

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);

            Utils.show(bt, bt.ico);
            Utils.hide(bt, bt.icoHover);
            Utils.hide(bt, bt.skinBgPress);
        }
    }

    /**
     * Иконка под текстом.
     * Используется по умолчанию.
     */
    static public var updateLayersIcoDown:SizeUpdater<Button> = function(bt) {
        if (Utils.eq(bt.state, ButtonState.HOVER)) {
            if (Utils.eq(bt.skinBgHover, null)) {
                Utils.show(bt, bt.skinBg);
                //Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.show(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
            }

            if (Utils.eq(bt.icoHover, null)) {
                Utils.show(bt, bt.ico);
                //Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.show(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
            }

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) {
            if (Utils.eq(bt.skinBgPress, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                //Utils.hide(bt, bt.skinBgPress);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.show(bt, bt.skinBgPress);
            }

            if (Utils.eq(bt.icoPress, null)) {
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                //Utils.hide(bt, bt.icoPress);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.show(bt, bt.icoPress);
            }

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);
        }
        else { // NORMAL
            Utils.show(bt, bt.skinBg);
            Utils.hide(bt, bt.skinBgHover);
            Utils.hide(bt, bt.skinBgPress);

            Utils.show(bt, bt.ico);
            Utils.hide(bt, bt.icoHover);
            Utils.hide(bt, bt.skinBgPress);

            if (Utils.eq(bt.text, ""))
                Utils.hide(bt, bt.label);
            else
                Utils.show(bt, bt.label);
        }
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Позицианирование иконки по верхнему, левому краю.
     * ```
     * +--------------------+
     * | X      Button with |
     * |          very long |
     * |         text label |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoTL:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
    }

    /**
     * Позицианирование иконки по центру левого края.
     * Используется по умолчанию.
     * ```
     * +--------------------+
     * |        Button with |
     * | X        very long |
     * |         text label |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoML:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
    }

    /**
     * Позицианирование иконки внизу левого края.
     * ```
     * +--------------------+
     * |        Button with |
     * |          very long |
     * | X       text label |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoBL:SizeUpdater<Button> = function(bt) {
        
    }

    /**
     * Позицианирование иконки по верхнему, правому краю.
     * ```
     * +--------------------+
     * | Button with      X |
     * | very long          |
     * | text label         |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoTR:SizeUpdater<Button> = function(bt) {
        
    }

    /**
     * Позицианирование иконки по центру правого края.
     * ```
     * +--------------------+
     * | Button with        |
     * | very long        X |
     * | text label         |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoMR:SizeUpdater<Button> = function(bt) {
        
    }

    /**
     * Позицианирование иконки внизу правого края.
     * ```
     * +--------------------+
     * | Button with        |
     * | very long          |
     * | text label       X |
     * +--------------------+ 
     * ```
     */
    static public var updateSizeIcoBR:SizeUpdater<Button> = function(bt) {
        
    }

    /**
     * Позицианирование иконки по центру над текстом.
     * ```
     * +-----------------+
     * |        X        |
     * |   Text button   |
     * +-----------------+ 
     * ```
     */
    static public var updateSizeIcoTC:SizeUpdater<Button> = function(bt) {
        
    }

    /**
     * Позицианирование иконки по центру под текстом.
     * ```
     * +-----------------+
     * |   Text button   |
     * |        X        |
     * +-----------------+ 
     * ```
     */
    static public var updateSizeIcoBC:SizeUpdater<Button> = function(bt) {
        
    }
}

/**
 * Состояние кнопки.
 * Описывает все возможные состояния, в которых может находиться кнопка.
 */
@:enum abstract ButtonState(Int) to Int
{
	/**
     * Нормальное состояние.
     * (Используется по умолчанию)
	 */
    var NORMAL = 0;
    
    /**
     * Наведение курсора.
     */
    var HOVER = 1;

    /**
     * Нажатие.
     */
    var PRESS = 2;
}