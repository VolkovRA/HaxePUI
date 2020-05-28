package pui;

import pui.Component;
import pui.Mouse;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

/**
 * Кнопка.
 * Может содержать текст и/или картинку.
 * 
 * События:
 * - `UIEvent.PRESS`            Нажатие на кнопку. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`. (`Button->Void`)
 * - `UIEvent.CLICK`            Клик по кнопке. Не путайте с `Event.CLICK`. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`. (`Button->Void`)
 * - `UIEvent.DOUBLE_CLICK`     Двойной клик по кнопке. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`. (`Button->Void`)
 * - `UIEvent.STATE`            Состояние кнопки изменено: `Button->ButtonState->Void`. (Передаёт старое состояние)
 * - `UIEvent.UPDATE`           Кнопка обновилась: `Button->changes->Void`. (Передаёт старые изменения)
 * - *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class Button extends Component
{
    /**
     * Тип компонента `Button`.
     */
    static public inline var TYPE:String = "Button";

    /**
     * Отсутствие отступов.
     * Используется как кешированный объект.
     */
    static private var paddingZero:Padding = { top:0, left:0, right:0, bottom:0 };

    /**
     * Создать кнопку.
     */
    public function new() {
        super(TYPE);
        
        this.buttonMode = true;
        this.interactive = true;

        Utils.set(this.updateLayers, Button.icoDown);
        Utils.set(this.updateSize, Button.pos8);

        on(Event.POINTER_OVER, onRollOver);
        on(Event.POINTER_OUT, onRollOut);
        on(Event.POINTER_DOWN, onDown);
        on(Event.POINTER_UP, onUp);
        on(Event.POINTER_UP_OUTSIDE, onUpOutside);


        on(UIEvent.PRESS, function(bt){ trace("PRESS!"); });
        on(UIEvent.CLICK, function(bt){ trace("CLICK!"); });
        on(UIEvent.DOUBLE_CLICK, function(bt){ trace("DOUBLE_CLICK!"); });
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onRollOver(e:InteractionEvent):Void {
        if (!enabled || (isPrimary && !e.data.isPrimary))
            return;

        if (downCurrentButton)
            state = ButtonState.PRESS;
        else
            state = ButtonState.HOVER;
    }
    private function onRollOut(e:InteractionEvent):Void {
        if (!enabled || (isPrimary && !e.data.isPrimary))
            return;

        state = ButtonState.NORMAL;
    }
    private function onDown(e:InteractionEvent):Void {
        if (!enabled || (isPrimary && !e.data.isPrimary))
            return;
        if (mouseInput != null && mouseInput.length != 0 && mouseInput.indexOf(e.data.button) == -1)
            return;

        downCurrentButton = true;
        state = ButtonState.PRESS;

        // Двойной клик:
        if (doubleClickParams.enabled) {
            var item = {
                t: Utils.uptime(),
                x: e.data.global.x,
                y: e.data.global.y,
            }

            var pre = history[e.data.identifier];
            if (pre == null || item.t > pre.t + doubleClickParams.time) {
                history[e.data.identifier] = item;
                emit(UIEvent.PRESS, this);
                return;
            }

            var dx = pre.x - item.x;
            var dy = pre.y - item.y;
            if (Math.abs(dx*dx + dy*dy) > doubleClickParams.dist * doubleClickParams.dist) {
                history[e.data.identifier] = item;
                emit(UIEvent.PRESS, this);
                return;
            }

            history[e.data.identifier] = null;
            
            emit(UIEvent.PRESS, this);
            emit(UIEvent.DOUBLE_CLICK, this);
            return;
        }
        
        emit(UIEvent.PRESS, this);
    }
    private function onUp(e:InteractionEvent):Void {
        if (!enabled || (isPrimary && !e.data.isPrimary))
            return;
        if (mouseInput != null && mouseInput.length != 0 && mouseInput.indexOf(e.data.button) == -1)
            return;
        
        downCurrentButton = false;
        state = ButtonState.HOVER;

        emit(UIEvent.CLICK, this);
    }
    private function onUpOutside(e:InteractionEvent):Void {
        if (!enabled || (isPrimary && !e.data.isPrimary))
            return;

        downCurrentButton = false;
        state = ButtonState.NORMAL;
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        if (!value) {
            state = ButtonState.NORMAL;
            downCurrentButton = false;
        }

        return super.set_enabled(value);
    }

    /**
     * Параметры срабатывания двойного нажатия.
     * Не может быть `null`.
     */
    public var doubleClickParams(default, null):DoubleClickParams = {
        enabled: true,
        time: 250,
        dist: 10,
    }

    /**
     * Использовать только основное устройство ввода.
     * 
     * Основное устройство - это мышь, первое касание на сенсорном устройстве или т.п.
     * - Если `true` - Кнопка будет реагировать только на ввод с основного устройства.
     * - Если `false` - Кнопка будет реагировать на ввод с любого устройства.
     * 
     * По умолчанию: `true`
     * 
     * @see PointerEvent.isPrimary: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/isPrimary
     */
    public var isPrimary:Bool = true;

    /**
     * Клавишы реагирования.
     * Позволяет установить, на какие кнопки мыши будет реагировать кнопка.
     * - Если `null` или пустой массив - Кнопка реагирует на любые клавишы.
     * 
     * По умолчанию: `[Mouse.MAIN]` (Только главная кнопка мыши)
     */
    public var mouseInput:Array<MouseKey> = [Mouse.MAIN];

    /**
     * Флаг активного нажатия.
     * Используется кнопкой, чтобы определить, нажали изначально по ней или нет.
     */
    private var downCurrentButton:Bool = false;

    /**
     * История кликов.
     * Используется для реализации события двойного клика.
     */
    private var history:Dynamic = {};

    /**
     * Текст на кнопке.
     * Для отображения текста вы должны назначить текстовую метку в свойстве: `label`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `""`, не может быть `null`.
     */
    public var text(default, set):String = "";
    function set_text(value:String):String {
        if (value == null) {
            if (Utils.eq(text, ""))
                return value;

            text = "";
            update(false, Component.UPDATE_SIZE);

            if (Utils.noeq(label, null))            label.text = "";
            if (Utils.noeq(labelHover, null))       labelHover.text = "";
            if (Utils.noeq(labelPress, null))       labelPress.text = "";
            if (Utils.noeq(labelDisable, null))     labelDisable.text = "";

            return value;
        }
        else {
            if (Utils.eq(value, text))
                return value;
            
            text = value;
            update(false, Component.UPDATE_SIZE);
    
            if (Utils.noeq(label, null))            label.text = value;
            if (Utils.noeq(labelHover, null))       labelHover.text = value;
            if (Utils.noeq(labelPress, null))       labelPress.text = value;
            if (Utils.noeq(labelDisable, null))     labelDisable.text = value;
            
            return value;
        }
    }

    /**
     * Состояние кнопки.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения скинов состояния.
     * - `Component.UPDATE_SIZE` - Для позицианирования элементов.
     * 
     * По умолчанию: `ButtonState.NORMAL`
     */
    public var state(default, set):ButtonState = ButtonState.NORMAL;
    function set_state(value:ButtonState):ButtonState {
        if (Utils.eq(value, state))
            return value;

        var olds = state;
        state = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        emit(UIEvent.STATE, this, olds);
        return value;
    }

    /**
     * Иконка на кнопке.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
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
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
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
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
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
     * Иконка на кнопке в выключенном состоянии. (`enabled=false`)
     * Если значение не задано, используется `ico`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoDisable(default, set):Container = null;
    function set_icoDisable(value:Container):Container {
        if (Utils.eq(value, icoDisable))
            return value;

        Utils.hide(this, icoDisable);
        icoDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ между иконкой и текстом. (px)
     * 
     * Используется только при наличии текста и иконки на кнопке, для задания расстояния между ними.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`.
     */
    public var icoGap(default, set):Float = 0;
    function set_icoGap(value:Float):Float {
        if (Utils.eq(value, icoGap))
            return value;

        icoGap = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Метка с текстом на кнопке.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`. (Текст на кнопке не будет отрисован)
     */
    public var label(default, set):Label = null;
    function set_label(value:Label):Label {
        if (Utils.eq(value, label))
            return value;

        Utils.hide(this, label);
        label = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке при наведении.
     * Если значение не задано, используется `label`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelHover(default, set):Label = null;
    function set_labelHover(value:Label):Label {
        if (Utils.eq(value, labelHover))
            return value;

        Utils.hide(this, labelHover);
        labelHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке при нажатии на кнопку.
     * Если значение не задано, используется `label`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelPress(default, set):Label = null;
    function set_labelPress(value:Label):Label {
        if (Utils.eq(value, labelPress))
            return value;

        Utils.hide(this, labelPress);
        labelPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке в выключенном состоянии.
     * Если значение не задано, используется `label`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelDisable(default, set):Label = null;
    function set_labelDisable(value:Label):Label {
        if (Utils.eq(value, labelDisable))
            return value;

        Utils.hide(this, labelDisable);
        labelDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Отступы содержимого.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var padding(default, set):Padding = null;
    function set_padding(value:Padding):Padding {
        if (Utils.eq(value, padding))
            return value;

        padding = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого при наведении курсора.
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingHover(default, set):Padding = null;
    function set_paddingHover(value:Padding):Padding {
        if (Utils.eq(value, paddingHover))
            return value;

        paddingHover = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого при нажатии.
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingPress(default, set):Padding = null;
    function set_paddingPress(value:Padding):Padding {
        if (Utils.eq(value, paddingPress))
            return value;

        paddingPress = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого в выключенном состоянии.
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingDisable(default, set):Padding = null;
    function set_paddingDisable(value:Padding):Padding {
        if (Utils.eq(value, paddingDisable))
            return value;

        paddingDisable = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при наведении курсора.
     * Если значение не задано, используется `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования скина.
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
     * - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования скина.
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
        if (Utils.noeq(labelHover, null)) {
            label.destroy(options);
            Utils.delete(labelHover);
        }
        if (Utils.noeq(labelPress, null)) {
            label.destroy(options);
            Utils.delete(labelPress);
        }
        if (Utils.noeq(labelDisable, null)) {
            label.destroy(options);
            Utils.delete(labelDisable);
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
        if (Utils.noeq(icoDisable, null)) {
            icoDisable.destroy(options);
            Utils.delete(icoDisable);
        }
        if (Utils.noeq(skinBgHover, null)) {
            skinBgHover.destroy(options);
            Utils.delete(skinBgHover);
        } 
        if (Utils.noeq(skinBgPress, null)) {
            skinBgPress.destroy(options);
            Utils.delete(skinBgPress);
        }

        super.destroy(options);
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Иконка над текстом.
     */
    static public var icoTop:SizeUpdater<Button> = function(bt) {
        if (!bt.enabled) {
            if (Utils.eq(bt.skinBgDisable, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                //Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.show(bt, bt.skinBgDisable);
            }
            
            if (Utils.eq(bt.labelDisable, null)) {
                Utils.show(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                //Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.show(bt, bt.labelDisable);
            }

            if (Utils.eq(bt.icoDisable, null)){
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                //Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.show(bt, bt.icoDisable);
            }
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) {
            if (Utils.eq(bt.skinBgHover, null)) {
                Utils.show(bt, bt.skinBg);
                //Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.show(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }

            if (Utils.eq(bt.labelHover, null)) {
                Utils.show(bt, bt.label);
                //Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.show(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }

            if (Utils.eq(bt.icoHover, null)) {
                Utils.show(bt, bt.ico);
                //Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.show(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) {
            if (Utils.eq(bt.skinBgPress, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                //Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.show(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }

            if (Utils.eq(bt.labelPress, null)) {
                Utils.show(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                //Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.show(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }

            if (Utils.eq(bt.icoPress, null)) {
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                //Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.show(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
        }
        else { // NORMAL
            Utils.show(bt, bt.skinBg);
            Utils.hide(bt, bt.skinBgHover);
            Utils.hide(bt, bt.skinBgPress);
            Utils.hide(bt, bt.skinBgDisable);

            Utils.show(bt, bt.label);
            Utils.hide(bt, bt.labelHover);
            Utils.hide(bt, bt.labelPress);
            Utils.hide(bt, bt.labelDisable);

            Utils.show(bt, bt.ico);
            Utils.hide(bt, bt.icoHover);
            Utils.hide(bt, bt.icoPress);
            Utils.hide(bt, bt.icoDisable);
        }
    }

    /**
     * Иконка под текстом.
     * Используется по умолчанию.
     */
    static public var icoDown:SizeUpdater<Button> = function(bt) {
        if (!bt.enabled) {
            if (Utils.eq(bt.skinBgDisable, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                //Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.show(bt, bt.skinBgDisable);
            }

            if (Utils.eq(bt.icoDisable, null)){
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                //Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.show(bt, bt.icoDisable);
            }

            if (Utils.eq(bt.labelDisable, null)) {
                Utils.show(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                //Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.show(bt, bt.labelDisable);
            }
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) {
            if (Utils.eq(bt.skinBgHover, null)) {
                Utils.show(bt, bt.skinBg);
                //Utils.hide(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.show(bt, bt.skinBgHover);
                Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }

            if (Utils.eq(bt.icoHover, null)) {
                Utils.show(bt, bt.ico);
                //Utils.hide(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.show(bt, bt.icoHover);
                Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }

            if (Utils.eq(bt.labelHover, null)) {
                Utils.show(bt, bt.label);
                //Utils.hide(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.show(bt, bt.labelHover);
                Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) {
            if (Utils.eq(bt.skinBgPress, null)) {
                Utils.show(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                //Utils.hide(bt, bt.skinBgPress);
                Utils.hide(bt, bt.skinBgDisable);
            }
            else {
                Utils.hide(bt, bt.skinBg);
                Utils.hide(bt, bt.skinBgHover);
                Utils.show(bt, bt.skinBgPress);
                Utils.show(bt, bt.skinBgDisable);
            }

            if (Utils.eq(bt.icoPress, null)) {
                Utils.show(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                //Utils.hide(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }
            else {
                Utils.hide(bt, bt.ico);
                Utils.hide(bt, bt.icoHover);
                Utils.show(bt, bt.icoPress);
                Utils.hide(bt, bt.icoDisable);
            }

            if (Utils.eq(bt.labelPress, null)) {
                Utils.show(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                //Utils.hide(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
            else {
                Utils.hide(bt, bt.label);
                Utils.hide(bt, bt.labelHover);
                Utils.show(bt, bt.labelPress);
                Utils.hide(bt, bt.labelDisable);
            }
        }
        else { // NORMAL
            Utils.show(bt, bt.skinBg);
            Utils.hide(bt, bt.skinBgHover);
            Utils.hide(bt, bt.skinBgPress);
            Utils.hide(bt, bt.skinBgDisable);

            Utils.show(bt, bt.ico);
            Utils.hide(bt, bt.icoHover);
            Utils.hide(bt, bt.icoPress);
            Utils.hide(bt, bt.icoDisable);

            Utils.show(bt, bt.label);
            Utils.hide(bt, bt.labelHover);
            Utils.hide(bt, bt.labelPress);
            Utils.hide(bt, bt.labelDisable);
        }
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Позицианирование 1:
     * ```
     * +--------------------+
     * | X      Button with |
     * |          very long |
     * |         text label |
     * |                    |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos1:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(p.top);
                
                ico.x = Math.round(p.left);
                ico.y = Math.round(p.top);
            }
            else {
                ico.x = Math.round(p.left);
                ico.y = Math.round(p.top);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(p.top);
            }
        }
    }

    /**
     * Позицианирование 2:
     * ```
     * +--------------------+
     * |                    |
     * |        Button with |
     * | X        very long |
     * |         text label |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos2:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
                
                ico.x = Math.round(p.left);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
            else {
                ico.x = Math.round(p.left);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
            }
        }
    }

    /**
     * Позицианирование 3:
     * ```
     * +--------------------+
     * |                    |
     * |                    |
     * |        Button with |
     * |          very long |
     * | X       text label |
     * +--------------------+ 
     * ```
     */
    static public var pos3:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(bt.h - label.h - p.bottom);
                
                ico.x = Math.round(p.left);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
            else {
                ico.x = Math.round(p.left);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.RIGHT;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(bt.w - label.w - p.right);
                label.y = Math.round(bt.h - label.h - p.bottom);
            }
        }
    }

    /**
     * Позицианирование 4:
     * ```
     * +--------------------+
     * | Button with      X |
     * | very long          |
     * | text label         |
     * |                    |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos4:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(p.top);
                
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(p.top);
            }
            else {
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(p.top);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(p.top);
            }
        }
    }

    /**
     * Позицианирование 5:
     * ```
     * +--------------------+
     * |                    |
     * | Button with        |
     * | very long        X |
     * | text label         |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos5:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
                
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
            else {
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
            }
        }
    }

    /**
     * Позицианирование 6:
     * ```
     * +--------------------+
     * |                    |
     * |                    |
     * | Button with        |
     * | very long          |
     * | text label       X |
     * +--------------------+ 
     * ```
     */
    static public var pos6:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(bt.h - label.h - p.bottom);
                
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
            else {
                ico.x = Math.round(bt.w - ico.width - p.right);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.LEFT;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left);
                label.y = Math.round(bt.h - label.h - p.bottom);
            }
        }
    }

    /**
     * Позицианирование 7:
     * ```
     * +--------------------+
     * |   X Button with    |
     * |      very long     |
     * |     text labels    |
     * |                    |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos7:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + bt.icoGap + ico.width + (bt.w - label.w - bt.icoGap - ico.width) / 2);
                label.y = Math.round(p.top);
                
                ico.x = Math.round(label.x - bt.icoGap - ico.width);
                ico.y = Math.round(p.top);
            }
            else {
                ico.x = Math.round(p.left + (bt.w - ico.width) / 2);
                ico.y = Math.round(p.top);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.TOP;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + (bt.w - label.w) / 2);
                label.y = Math.round(p.top);
            }
        }
    }

    /**
     * Позицианирование 8: *(По умолчанию)*
     * ```
     * +--------------------+
     * |                    |
     * |     Button with    |
     * |   X  very long     |
     * |     text labels    |
     * |                    |
     * +--------------------+ 
     * ```
     */
    static public var pos8:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + bt.icoGap + ico.width + (bt.w - label.w - bt.icoGap - ico.width) / 2);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
                
                ico.x = Math.round(label.x - bt.icoGap - ico.width);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
            else {
                ico.x = Math.round(p.left + (bt.w - ico.width) / 2);
                ico.y = Math.round(p.top + (bt.h - ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.CENTER;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + (bt.w - label.w) / 2);
                label.y = Math.round(p.top + (bt.h - label.h) / 2);
            }
        }
    }

    /**
     * Позицианирование 9:
     * ```
     * +--------------------+
     * |                    |
     * |                    |
     * |     Button with    |
     * |      very long     |
     * |   X text labels    |
     * +--------------------+ 
     * ```
     */
    static public var pos9:SizeUpdater<Button> = function(bt) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        
        // Параметры:
        var ico = bt.ico;
        var label = bt.label;
        var p = Utils.eq(bt.padding, null)?paddingZero:bt.padding;

        // Состояние:
        if (!bt.enabled) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null))    p = bt.paddingDisable;
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null))      p = bt.paddingHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null))      p = bt.paddingPress;
        }

        // Позицианирование:
        if (Utils.noeq(ico, null)) {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + bt.icoGap + ico.width + (bt.w - label.w - bt.icoGap - ico.width) / 2);
                label.y = Math.round(bt.h - label.h - p.bottom);
                
                ico.x = Math.round(label.x - bt.icoGap - ico.width);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
            else {
                ico.x = Math.round(p.left + (bt.w - ico.width) / 2);
                ico.y = Math.round(bt.h - ico.height - p.bottom);
            }
        }
        else {
            if (Utils.noeq(label, null)) {
                label.alignX = AlignX.CENTER;
                label.alignY = AlignY.BOTTOM;
                label.autosize = true;
                label.update(true);
                label.x = Math.round(p.left + (bt.w - label.w) / 2);
                label.y = Math.round(bt.h - label.h - p.bottom);
            }
        }
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

/**
 * Параметры настройки двойного клика.
 */
typedef DoubleClickParams =
{
    /**
     * Двойное нажатие включено.
     * Если `true` - Кнопка будет регистрировать двойные нажатия.
     * 
     * По умолчанию: `true`
     */
    var enabled:Bool;

    /**
     * Максимальное время между двумя кликами. (mc)
     * 
     * По умолчанию: `250` (Четверть секунды)
     */
    var time:Int;

    /**
     * Максимальная дистанция между кликами. (px)
     * 
     * Позволяет более тонко настроить срабатывание двойного нажатия,
     * когда между кликами бывает небольшой зазор из-за смещения курсора.
     * 
     * По умолчанию: `10`
     */
    var dist:Float;
}