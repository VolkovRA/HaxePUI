package pui.ui;

import haxe.extern.EitherType;
import pixi.display.Container;
import pixi.events.InteractionEvent;
import pui.events.Event;
import pui.ui.Component;

/**
 * Зажимная кнопка.
 * Может содержать текст и/или картинку.
 * 
 * Похожа на обычную кнопку но с тем отличием, что может
 * находиться в двух состояниях: `Нажата` и `Не нажата`. (См.: `value`)
 * Идеально подходит для выключателя света.
 * 
 * @event Event.CHANGE              Кнопка: вкл/выкл. Диспетчерезируется при изменении значения кнопки: `value`.
 * @event Event.PRESS               Нажатие на кнопку. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * @event Event.CLICK               Клик по кнопке. Не путайте с событиями PixiJS. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * @event Event.STATE               Состояние кнопки изменено.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class ToggleButton extends Component
{
    /**
     * Тип компонента `ToggleButton`.
     */
    static public inline var TYPE:String = "ToggleButton";

    // Приват
    private var isHover:Bool = false;
    private var isPress:Bool = false;

    /**
     * Создать кнопку.
     */
    public function new() {
        super();

        this.componentType = TYPE;
        this.buttonMode = true;
        this.interactive = true;

        Utils.set(this.updateLayers, ToggleButton.icoDown);
        Utils.set(this.updateSize, ToggleButton.pos8);

        on(InteractionEvent.POINTER_OVER, onRollOver);
        on(InteractionEvent.POINTER_OUT, onRollOut);
        on(InteractionEvent.POINTER_DOWN, onDown);
        on(InteractionEvent.POINTER_UP, onUp);
        on(InteractionEvent.POINTER_UP_OUTSIDE, onUpOutside);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onRollOver(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        isHover = true;
        updateState();
    }
    private function onRollOut(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;
        
        // Автонажатие:
        isHover = false;
        updateState();
    }
    private function onDown(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        e.stopPropagation();
        isPress = true;
        updateState();
        Event.fire(Event.PRESS, this);
    }
    private function onUp(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;
        
        if (isPress) {
            isPress = false;
            value = !value;
            Event.fire(Event.CLICK, this);
        }
        
        updateState();
    }
    private function onUpOutside(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        isPress = false;
        updateState();
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
            buttonMode = false;
            interactive = false;
        }

        super.set_enabled(value);
        updateState();
        return value;
    }

    /**
     * Кнопка вкл/выкл.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения слоёв.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `false`. (Кнопка не включена)
     */
    public var value(default, set):Bool = false;
    function set_value(v:Bool):Bool {
        if (Utils.eq(v, value))
            return v;

        value = v;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        Event.fire(Event.CHANGE, this);
        return v;
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
     * Изменяется автоматически при взаимодействии пользователя с компонентом.
     * Используется как индикатор для отображения необходимых текстур.
     * 
     * По умолчанию: `ToggleButtonState.NORMAL`. (Обычно есостояние)
     * 
     * @event Event.STATE  Посылается в случае изменения состояния.
     */
    public var state(default, null):ToggleButtonState = ToggleButtonState.NORMAL;

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

    /**
     * Иконка на кнопке. (Включенная кнопка)
     * Если значение не задано, используется `ico`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoActive(default, set):Container = null;
    function set_icoActive(value:Container):Container {
        if (Utils.eq(value, icoActive))
            return value;

        Utils.hide(this, icoActive);
        icoActive = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Иконка на кнопке при наведении курсора. (Включенная кнопка)
     * Если значение не задано, используется `icoActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoActiveHover(default, set):Container = null;
    function set_icoActiveHover(value:Container):Container {
        if (Utils.eq(value, icoActiveHover))
            return value;

        Utils.hide(this, icoActiveHover);
        icoActiveHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Иконка на кнопке при нажатии. (Включенная кнопка)
     * Если значение не задано, используется `icoActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoActivePress(default, set):Container = null;
    function set_icoActivePress(value:Container):Container {
        if (Utils.eq(value, icoActivePress))
            return value;

        Utils.hide(this, icoActivePress);
        icoActivePress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Иконка на кнопке в выключенном состоянии. (`enabled=false`) (Включенная кнопка)
     * Если значение не задано, используется `icoActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления иконки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования иконки.
     * 
     * По умолчанию: `null`.
     */
    public var icoActiveDisable(default, set):Container = null;
    function set_icoActiveDisable(value:Container):Container {
        if (Utils.eq(value, icoActiveDisable))
            return value;

        Utils.hide(this, icoActiveDisable);
        icoActiveDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Метка с текстом на кнопке. (Включенная кнопка)
     * Если значение не задано, используется `label`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`. (Текст на кнопке не будет отрисован)
     */
    public var labelActive(default, set):Label = null;
    function set_labelActive(value:Label):Label {
        if (Utils.eq(value, labelActive))
            return value;

        Utils.hide(this, labelActive);
        labelActive = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке при наведении. (Включенная кнопка)
     * Если значение не задано, используется `labelActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelActiveHover(default, set):Label = null;
    function set_labelActiveHover(value:Label):Label {
        if (Utils.eq(value, labelActiveHover))
            return value;

        Utils.hide(this, labelActiveHover);
        labelActiveHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке при нажатии на кнопку. (Включенная кнопка)
     * Если значение не задано, используется `labelActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelActivePress(default, set):Label = null;
    function set_labelActivePress(value:Label):Label {
        if (Utils.eq(value, labelActivePress))
            return value;

        Utils.hide(this, labelActivePress);
        labelActivePress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Метка с текстом на кнопке в выключенном состоянии. (Включенная кнопка)
     * Если значение не задано, используется `labelActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления метки в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования метки.
     * 
     * По умолчанию: `null`.
     */
    public var labelActiveDisable(default, set):Label = null;
    function set_labelActiveDisable(value:Label):Label {
        if (Utils.eq(value, labelActiveDisable))
            return value;

        Utils.hide(this, labelActiveDisable);
        labelActiveDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        value.text = text;
        return value;
    }

    /**
     * Отступы содержимого. (Включенная кнопка)
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingActive(default, set):Offset = null;
    function set_paddingActive(value:Offset):Offset {
        if (Utils.eq(value, paddingActive))
            return value;

        paddingActive = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого при наведении курсора. (Включенная кнопка)
     * Если не задано, используется `paddingActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingActiveHover(default, set):Offset = null;
    function set_paddingActiveHover(value:Offset):Offset {
        if (Utils.eq(value, paddingActiveHover))
            return value;

        paddingActiveHover = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого при нажатии. (Включенная кнопка)
     * Если не задано, используется `paddingActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingActivePress(default, set):Offset = null;
    function set_paddingActivePress(value:Offset):Offset {
        if (Utils.eq(value, paddingActivePress))
            return value;

        paddingActivePress = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступы содержимого в выключенном состоянии. (Включенная кнопка)
     * Если не задано, используется `paddingActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`.
     */
    public var paddingActiveDisable(default, set):Offset = null;
    function set_paddingActiveDisable(value:Offset):Offset {
        if (Utils.eq(value, paddingActiveDisable))
            return value;

        paddingActiveDisable = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при наведении курсора. (Включенная кнопка)
     * Если значение не задано, используется `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования скина.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgActive(default, set):Container = null;
    function set_skinBgActive(value:Container):Container {
        if (Utils.eq(value, skinBgActive))
            return value;

        Utils.hide(this, skinBgActive);
        skinBgActive = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при наведении курсора. (Включенная кнопка)
     * Если значение не задано, используется `skinBgActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования скина.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgActiveHover(default, set):Container = null;
    function set_skinBgActiveHover(value:Container):Container {
        if (Utils.eq(value, skinBgActiveHover))
            return value;

        Utils.hide(this, skinBgActiveHover);
        skinBgActiveHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона при нажатии. (Включенная кнопка)
     * Если значение не задано, используется `skinBgActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления скина в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для позицианирования скина.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgActivePress(default, set):Container = null;
    function set_skinBgActivePress(value:Container):Container {
        if (Utils.eq(value, skinBgActivePress))
            return value;

        Utils.hide(this, skinBgActivePress);
        skinBgActivePress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона выключенного состояния. (Включенная кнопка)
     * Если значение не задано, используется `skinBgActive`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона выключенного состояния.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона выключенного состояния.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgActiveDisable(default, set):Container = null;
    function set_skinBgActiveDisable(value:Container):Container {
        if (Utils.eq(value, skinBgActiveDisable))
            return value;

        Utils.hide(this, skinBgActiveDisable);
        skinBgActiveDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Обновить состояние кнопки.
     * Интерпретирует текущее состояние компонента и записывает его в свойство: `state`.
     * @event Event.STATE - Отправляется в случае изменения значения: `state`.
     */
    private function updateState():Void {
        var v = state;
        if (enabled) {
            if (value) {
                if (isPress)        v = ToggleButtonState.ACTIVE_PRESS;
                else if (isHover)   v = ToggleButtonState.ACTIVE_HOVER;
                else                v = ToggleButtonState.ACTIVE_NORMAL;
            }
            else {
                if (isPress)        v = ToggleButtonState.PRESS;
                else if (isHover)   v = ToggleButtonState.HOVER;
                else                v = ToggleButtonState.NORMAL;
            }
        }
        else {
            if (value)
                v = ToggleButtonState.ACTIVE_DISABLED;
            else
                v = ToggleButtonState.DISABLED;
        }

        if (Utils.eq(v, state))
            return;

        state = v;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        Event.fire(Event.STATE, this);
    }

    /**
     * Выгрузить кнопку.
	 */
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        Utils.destroySkin(label, options);
        Utils.destroySkin(labelHover, options);
        Utils.destroySkin(labelPress, options);
        Utils.destroySkin(labelDisable, options);

        Utils.destroySkin(labelActive, options);
        Utils.destroySkin(labelActiveHover, options);
        Utils.destroySkin(labelActivePress, options);
        Utils.destroySkin(labelActiveDisable, options);

        Utils.destroySkin(ico, options);
        Utils.destroySkin(icoHover, options);
        Utils.destroySkin(icoPress, options);
        Utils.destroySkin(icoDisable, options);

        Utils.destroySkin(icoActive, options);
        Utils.destroySkin(icoActiveHover, options);
        Utils.destroySkin(icoActivePress, options);
        Utils.destroySkin(icoActiveDisable, options);

        Utils.destroySkin(skinBgHover, options);
        Utils.destroySkin(skinBgPress, options);
        Utils.destroySkin(skinBgPress, options);

        Utils.destroySkin(skinBgActive, options);
        Utils.destroySkin(skinBgActiveHover, options);
        Utils.destroySkin(skinBgActivePress, options);
        Utils.destroySkin(skinBgActiveDisable, options);

        super.destroy(options);
    }



    ////////////////////////////////
    //   ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ   //
    ////////////////////////////////

    /**
     * Отображение слоёв в заданном порядке.
     * Этом метод используется для изменения порядка отображения слоёв и их показа.
     * @param skins Все скины, учавствующие в отображении. (В порядке отображения)
     * @param bt Настраиваемая кнопка.
     */
    static public function showLayers(skins:Array<Container>, bt:ToggleButton):Void {
        
        // Настройка слоёв.
        // Базовые скины, если не будет указано иное:
        var bg:Container    = bt.skinBg;
        var ico:Container   = bt.ico;
        var label:Label     = bt.label;

        // Скины второго порядка: (Если не будут заданы конкретные)
        if (bt.value) {
            if (bt.skinBgActive != null)    bg = bt.skinBgActive;
            if (bt.icoActive != null)       ico = bt.icoActive;
            if (bt.labelActive != null)     label = bt.labelActive;
        }

        // Конкретные скины:
        if (Utils.eq(bt.state, ToggleButtonState.HOVER)) {
            if (bt.skinBgHover != null)     bg = bt.skinBgHover;
            if (bt.labelHover != null)      label = bt.labelHover;
            if (bt.icoHover != null)        ico = bt.icoHover;
        }
        else if (Utils.eq(bt.state, ToggleButtonState.PRESS)) {
            if (bt.skinBgPress != null)     bg = bt.skinBgPress;
            if (bt.labelPress != null)      label = bt.labelPress;
            if (bt.icoPress != null)        ico = bt.icoPress;
        }
        else if (Utils.eq(bt.state, ToggleButtonState.DISABLED)) {
            if (bt.skinBgDisable != null)   bg = bt.skinBgDisable;
            if (bt.labelDisable != null)    label = bt.labelDisable;
            if (bt.icoDisable != null)      ico = bt.icoDisable;
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_HOVER)) {
            if (bt.skinBgActiveHover != null)   bg = bt.skinBgActiveHover;
            if (bt.labelActiveHover != null)    label = bt.labelActiveHover;
            if (bt.icoActiveHover != null)      ico = bt.icoActiveHover;
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_PRESS)) {
            if (bt.skinBgActivePress != null)   bg = bt.skinBgActivePress;
            if (bt.labelActivePress != null)    label = bt.labelActivePress;
            if (bt.icoActivePress != null)      ico = bt.icoActivePress;
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_DISABLED)) {
            if (bt.skinBgActiveDisable != null)   bg = bt.skinBgActiveDisable;
            if (bt.labelActiveDisable != null)    label = bt.labelActiveDisable;
            if (bt.icoActiveDisable != null)      ico = bt.icoActiveDisable;
        }
        
        // Отображение:
        var i = 0;
        var len = skins.length;
        while (i < len) {
            var skin = skins[i++];
            if (skin == null)
                continue;
            
            if (Utils.eq(skin, bg) || Utils.eq(skin, ico) || Utils.eq(skin, label)) {
                bt.addChild(skin);
            }
            else {
                if (Utils.eq(skin.parent, bt))
                    bt.removeChild(skin);
            }
        }
    }

    /**
     * Выполнить базвое позицианирование.
     * 
     * Растягивает все скины, интерпретирует состояние кнопки и возвращает
     * объект со скинами, которые необходимо отпозицианировать.
     * @param bt Настраиваемая кнопка.
     * @return Параметры для позицианирования.
     */
    static public function basePos(bt:ToggleButton) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);
        Utils.size(bt.skinBgActive, bt.w, bt.h);
        Utils.size(bt.skinBgActiveHover, bt.w, bt.h);
        Utils.size(bt.skinBgActivePress, bt.w, bt.h);
        Utils.size(bt.skinBgActiveDisable, bt.w, bt.h);

        // Используемые значения:
        var p =
        {
            ico:    bt.ico,
            label:  bt.label,
            pt:     0.0,
            pr:     0.0,
            pl:     0.0,
            pb:     0.0
        };

        // Отступы:
        if (bt.padding != null) {
            if (bt.padding.top != null)     p.pt = bt.padding.top;
            if (bt.padding.left != null)    p.pl = bt.padding.left;
            if (bt.padding.right != null)   p.pr = bt.padding.right;
            if (bt.padding.bottom != null)  p.pb = bt.padding.bottom;
        }

        // Промежуточное состояние:
        if (bt.value) {
            if (Utils.noeq(bt.icoActive, null))        p.ico = bt.icoActive;
            if (Utils.noeq(bt.labelActive, null))      p.label = bt.labelActive;
            if (Utils.noeq(bt.paddingActive, null)) {
                if (bt.paddingActive.top != null)      p.pt = bt.paddingActive.top;
                if (bt.paddingActive.left != null)     p.pl = bt.paddingActive.left;
                if (bt.paddingActive.right != null)    p.pr = bt.paddingActive.right;
                if (bt.paddingActive.bottom != null)   p.pb = bt.paddingActive.bottom;
            }
        }

        // Состояние:
        if (Utils.eq(bt.state, ToggleButtonState.DISABLED)) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        p.ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      p.label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null)) {
                if (bt.paddingDisable.top != null)      p.pt = bt.paddingDisable.top;
                if (bt.paddingDisable.left != null)     p.pl = bt.paddingDisable.left;
                if (bt.paddingDisable.right != null)    p.pr = bt.paddingDisable.right;
                if (bt.paddingDisable.bottom != null)   p.pb = bt.paddingDisable.bottom;
            }
        }
        else if (Utils.eq(bt.state, ToggleButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          p.ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        p.label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null)) {
                if (bt.paddingHover.top != null)        p.pt = bt.paddingHover.top;
                if (bt.paddingHover.left != null)       p.pl = bt.paddingHover.left;
                if (bt.paddingHover.right != null)      p.pr = bt.paddingHover.right;
                if (bt.paddingHover.bottom != null)     p.pb = bt.paddingHover.bottom;
            }
        }
        else if (Utils.eq(bt.state, ToggleButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          p.ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        p.label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null)) {
                if (bt.paddingPress.top != null)        p.pt = bt.paddingPress.top;
                if (bt.paddingPress.left != null)       p.pl = bt.paddingPress.left;
                if (bt.paddingPress.right != null)      p.pr = bt.paddingPress.right;
                if (bt.paddingPress.bottom != null)     p.pb = bt.paddingPress.bottom;
            }
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_HOVER)) { // Наведение (Включена)
            if (Utils.noeq(bt.icoActiveHover, null))    p.ico = bt.icoActiveHover;
            if (Utils.noeq(bt.labelActiveHover, null))  p.label = bt.labelActiveHover;
            if (Utils.noeq(bt.paddingActiveHover, null)) {
                if (bt.paddingActiveHover.top != null)        p.pt = bt.paddingActiveHover.top;
                if (bt.paddingActiveHover.left != null)       p.pl = bt.paddingActiveHover.left;
                if (bt.paddingActiveHover.right != null)      p.pr = bt.paddingActiveHover.right;
                if (bt.paddingActiveHover.bottom != null)     p.pb = bt.paddingActiveHover.bottom;
            }
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_PRESS)) { // Нажатие (Включена)
            if (Utils.noeq(bt.icoActivePress, null))          p.ico = bt.icoActivePress;
            if (Utils.noeq(bt.labelActivePress, null))        p.label = bt.labelActivePress;
            if (Utils.noeq(bt.paddingActivePress, null)) {
                if (bt.paddingActivePress.top != null)        p.pt = bt.paddingActivePress.top;
                if (bt.paddingActivePress.left != null)       p.pl = bt.paddingActivePress.left;
                if (bt.paddingActivePress.right != null)      p.pr = bt.paddingActivePress.right;
                if (bt.paddingActivePress.bottom != null)     p.pb = bt.paddingActivePress.bottom;
            }
        }
        else if (Utils.eq(bt.state, ToggleButtonState.ACTIVE_DISABLED)) { // Выключена (Включена)
            if (Utils.noeq(bt.icoActiveDisable, null))        p.ico = bt.icoActiveDisable;
            if (Utils.noeq(bt.labelActiveDisable, null))      p.label = bt.labelActiveDisable;
            if (Utils.noeq(bt.paddingActiveDisable, null)) {
                if (bt.paddingActiveDisable.top != null)      p.pt = bt.paddingActiveDisable.top;
                if (bt.paddingActiveDisable.left != null)     p.pl = bt.paddingActiveDisable.left;
                if (bt.paddingActiveDisable.right != null)    p.pr = bt.paddingActiveDisable.right;
                if (bt.paddingActiveDisable.bottom != null)   p.pb = bt.paddingActiveDisable.bottom;
            }
        }

        return p;
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Иконка над текстом.
     */
    static public var icoTop:SizeUpdater<ToggleButton> = function(bt) {
        showLayers([
            bt.skinBg,
            bt.skinBgHover,
            bt.skinBgPress,
            bt.skinBgDisable,

            bt.skinBgActive,
            bt.skinBgActiveHover,
            bt.skinBgActivePress,
            bt.skinBgActiveDisable,

            bt.label,
            bt.labelHover,
            bt.labelPress,
            bt.labelDisable,

            bt.labelActive,
            bt.labelActiveHover,
            bt.labelActivePress,
            bt.labelActiveDisable,

            bt.ico,
            bt.icoHover,
            bt.icoPress,
            bt.icoDisable,

            bt.icoActive,
            bt.icoActiveHover,
            bt.icoActivePress,
            bt.icoActiveDisable,
        ], bt);
    }

    /**
     * Иконка под текстом.
     * Используется по умолчанию.
     */
    static public var icoDown:SizeUpdater<ToggleButton> = function(bt) {
        showLayers([
            bt.skinBg,
            bt.skinBgHover,
            bt.skinBgPress,
            bt.skinBgDisable,

            bt.skinBgActive,
            bt.skinBgActiveHover,
            bt.skinBgActivePress,
            bt.skinBgActiveDisable,

            bt.ico,
            bt.icoHover,
            bt.icoPress,
            bt.icoDisable,

            bt.icoActive,
            bt.icoActiveHover,
            bt.icoActivePress,
            bt.icoActiveDisable,

            bt.label,
            bt.labelHover,
            bt.labelPress,
            bt.labelDisable,

            bt.labelActive,
            bt.labelActiveHover,
            bt.labelActivePress,
            bt.labelActiveDisable,
        ], bt);
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
    static public var pos1:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(p.pt);
                
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(p.pt);
            }
            else {
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(p.pt);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(p.pt);
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
    static public var pos2:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
                
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
            else {
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
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
    static public var pos3:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
                
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
            else {
                p.ico.x = Math.round(p.pl);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.RIGHT;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(bt.w - p.label.w - p.pr);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
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
    static public var pos4:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(p.pt);
                
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(p.pt);
            }
            else {
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(p.pt);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(p.pt);
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
    static public var pos5:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
                
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
            else {
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
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
    static public var pos6:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
                
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
            else {
                p.ico.x = Math.round(bt.w - p.ico.width - p.pr);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.LEFT;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
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
    static public var pos7:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + bt.icoGap + p.ico.width + (bt.w - p.label.w - bt.icoGap - p.ico.width) / 2);
                p.label.y = Math.round(p.pt);
                
                p.ico.x = Math.round(p.label.x - bt.icoGap - p.ico.width);
                p.ico.y = Math.round(p.pt);
            }
            else {
                p.ico.x = Math.round(p.pl + (bt.w - p.ico.width) / 2);
                p.ico.y = Math.round(p.pt);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.TOP;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + (bt.w - p.label.w) / 2);
                p.label.y = Math.round(p.pt);
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
    static public var pos8:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);
        
        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + bt.icoGap + p.ico.width + (bt.w - p.label.w - bt.icoGap - p.ico.width) / 2);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
                
                p.ico.x = Math.round(p.label.x - bt.icoGap - p.ico.width);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
            else {
                p.ico.x = Math.round(p.pl + (bt.w - p.ico.width) / 2);
                p.ico.y = Math.round(p.pt + (bt.h - p.ico.height) / 2);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.CENTER;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + (bt.w - p.label.w) / 2);
                p.label.y = Math.round(p.pt + (bt.h - p.label.h) / 2);
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
    static public var pos9:SizeUpdater<ToggleButton> = function(bt) {
        var p = basePos(bt);

        // Позицианирование:
        if (Utils.noeq(p.ico, null)) {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + bt.icoGap + p.ico.width + (bt.w - p.label.w - bt.icoGap - p.ico.width) / 2);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
                
                p.ico.x = Math.round(p.label.x - bt.icoGap - p.ico.width);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
            else {
                p.ico.x = Math.round(p.pl + (bt.w - p.ico.width) / 2);
                p.ico.y = Math.round(bt.h - p.ico.height - p.pb);
            }
        }
        else {
            if (Utils.noeq(p.label, null)) {
                p.label.alignX = AlignX.CENTER;
                p.label.alignY = AlignY.BOTTOM;
                p.label.autosize = true;
                p.label.update(true);
                p.label.x = Math.round(p.pl + (bt.w - p.label.w) / 2);
                p.label.y = Math.round(bt.h - p.label.h - p.pb);
            }
        }
    }
}

/**
 * Состояние зажимной кнопки.
 * Описывает все возможные состояния в которых может находиться кнопка.
 */
@:enum abstract ToggleButtonState(Int) to Int
{
    /**
     * Нормальное состояние.
     */
    var NORMAL = 0;

    /**
     * Наведение на кнопку.
     */
    var HOVER = 1;

    /**
     * Нажатие на кнопку.
     */
    var PRESS = 2;

    /**
     * Кнопка выключена.
     */
    var DISABLED = 3;

    /**
     * Активная кнопка в нормальном состоянии.
     */
    var ACTIVE_NORMAL = 10;

    /**
     * Активная кнопка при наведении.
     */
    var ACTIVE_HOVER = 11;

    /**
     * Активная кнопка нажата.
     */
    var ACTIVE_PRESS = 12;

    /**
     * Активная кнопка в выключенном состоянии.
     */
    var ACTIVE_DISABLED = 13;
}