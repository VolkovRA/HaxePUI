package pui.ui;

import js.Browser;
import pui.ui.Component;
import pui.events.Event;
import pui.dom.PointerType;
import pui.pixi.PixiEvent;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

/**
 * Кнопка.
 * Может содержать текст и/или картинку.
 * 
 * События:
 * - `Event.PRESS`              Нажатие на кнопку. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * - `Event.CLICK`              Клик по кнопке. Не путайте с событиями PixiJS. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * - `Event.DOUBLE_CLICK`       Двойной клик по кнопке. Необходимо отдельно включить в настройках кнопки: `Button.dblClick.enabled = true`.
 * - `Event.STATE`              Состояние кнопки изменено.
 * - `ComponentEvent.UPDATE`    Обновление компонента. (Перерисовка)
 * - `WheelEvent.WHEEL`         Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 * - *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class Button extends Component
{
    /**
     * Тип компонента `Button`.
     */
    static public inline var TYPE:String = "Button";

    /**
     * Кешированный отступ.
     * Используется для повторных вычислений внутри компонента.
     */
    static private var PADDING:Offset = { top:0, left:0, right:0, bottom:0 };

    // Приват
    private var history:Dynamic = {};
    private var downCurrentButton:Bool = false;
    private var autopressTimeout:Int = 0;
    private var autopressInterval:Int = 0;

    /**
     * Создать кнопку.
     */
    public function new() {
        super(TYPE);
        
        this.buttonMode = true;
        this.interactive = true;

        Utils.set(this.updateLayers, Button.icoDown);
        Utils.set(this.updateSize, Button.pos8);

        on(PixiEvent.POINTER_OVER, onRollOver);
        on(PixiEvent.POINTER_OUT, onRollOut);
        on(PixiEvent.POINTER_DOWN, onDown);
        on(PixiEvent.POINTER_UP, onUp);
        on(PixiEvent.POINTER_UP_OUTSIDE, onUpOutside);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onRollOver(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;

        if (downCurrentButton)
            state = ButtonState.PRESS;
        else
            state = ButtonState.HOVER;
    }
    private function onRollOut(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;

        state = ButtonState.NORMAL;

        // Автонажатие:
        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
        }
    }
    private function onDown(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;

        e.stopPropagation();

        downCurrentButton = true;
        state = ButtonState.PRESS;

        // Автонажатие:
        if (autopress.enabled && autopressInterval == 0 && autopressTimeout == 0) {
            autopressTimeout = Browser.window.setTimeout(function(){
                if (autopressInterval == 0) {
                    autopressInterval = Browser.window.setInterval(function(){
                        var e = Event.get(Event.PRESS, this);
                        emit(Event.PRESS, e);
                        Event.store(e);
                    }, autopress.interval);
                }
            }, autopress.delay);
        }

        // Двойной клик:
        if (dblClick.enabled) {
            var item = {
                t: Utils.uptime(),
                x: e.data.global.x,
                y: e.data.global.y,
            }

            var pre = history[e.data.identifier];
            if (pre == null || item.t > pre.t + dblClick.time) {
                history[e.data.identifier] = item;
                var e = Event.get(Event.PRESS, this);
                emit(Event.PRESS, e);
                Event.store(e);
                return;
            }

            var dx = pre.x - item.x;
            var dy = pre.y - item.y;
            if (Math.abs(dx*dx + dy*dy) > dblClick.dist * dblClick.dist) {
                history[e.data.identifier] = item;
                var e = Event.get(Event.PRESS, this);
                emit(Event.PRESS, e);
                Event.store(e);
                return;
            }

            history[e.data.identifier] = null;
            
            var e = Event.get(Event.PRESS, this);
            var e2 = Event.get(Event.DOUBLE_CLICK, this);
            emit(Event.PRESS, e);
            emit(Event.DOUBLE_CLICK, e2);
            Event.store(e);
            Event.store(e2);
            return;
        }
        
        var e = Event.get(Event.PRESS, this);
        emit(Event.PRESS, e);
        Event.store(e);
    }
    private function onUp(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;
        if (Utils.eq(e.data.pointerType, PointerType.MOUSE) && inputMouse != null && inputMouse.length != 0 && inputMouse.indexOf(e.data.button) == -1)
            return;
        
        downCurrentButton = false;
        state = ButtonState.HOVER;

        // Автонажатие:
        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
        }

        var e = Event.get(Event.CLICK, this);
        emit(Event.CLICK, e);
        Event.store(e);
    }
    private function onUpOutside(e:InteractionEvent):Void {
        if (!enabled || (inputPrimary && !e.data.isPrimary))
            return;

        downCurrentButton = false;
        state = ButtonState.NORMAL;

        // Автонажатие:
        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
        }
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        if (Utils.eq(value, enabled))
            return value;
        
        if (value) {
            buttonMode = true;
            interactive = true;
        }
        else {
            state = ButtonState.NORMAL;
            downCurrentButton = false;
            buttonMode = false;
            interactive = false;
        }

        return super.set_enabled(value);
    }

    /**
     * Параметры срабатывания двойного нажатия.
     * Позволяет включить/выключить отправку событий двойного клика по кнопке.
     * 
     * Не может быть `null`.
     */
    public var dblClick(default, null):DoubleClickParams = {
        enabled: false,
        time: 250,
        dist: 10,
    }

    /**
     * Параметры автонажатия.
     * Позволяет включить/выключить отправку повторных событий при долгом нажатии на кнопку.
     * 
     * Не может быть `null`.
     */
    public var autopress(default, null):AutoPressParams = {
        enabled: false,
        delay: 250,
        interval: 20,
    }

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

        state = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);

        var e = Event.get(Event.STATE, this);
        emit(Event.STATE, e);
        Event.store(e);

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
     * Отступы содержимого при наведении курсора.
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingHover(default, set):Offset = null;
    function set_paddingHover(value:Offset):Offset {
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
    public var paddingPress(default, set):Offset = null;
    function set_paddingPress(value:Offset):Offset {
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
    public var paddingDisable(default, set):Offset = null;
    function set_paddingDisable(value:Offset):Offset {
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

        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
        var p = Utils.eq(bt.padding, null)?PADDING:bt.padding;

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
     * Если `true` - Кнопка будет посылать события двойные нажатия: `Event.DOUBLE_CLICK`.
     * 
     * По умолчанию: `false` (Выключено)
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

/**
 * Параметры настройки автоматического нажатия.
 */
typedef AutoPressParams =
{
    /**
     * Авто нажатие включено.
     * Если `true` - Кнопка будет посылать события нажатия при длительном нажатии на кнопку: `Event.PRESS`.
     * 
     * По умолчанию: `false` (Выключено)
     */
    var enabled:Bool;

    /**
     * Задержка после первого нажатия и перед запуском отправки событий. (mc)
     * 
     * По умолчанию: `250` (Четверть секунды)
     */
    var delay:Int;

    /**
     * Интервал отправки событий. (mc)
     * 
     * По умолчанию: `25` (40 Раз в секунду)
     */
    var interval:Int;
}