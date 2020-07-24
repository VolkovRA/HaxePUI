package pui.ui;

import js.Browser;
import pui.ui.Component;
import pui.events.Event;
import pui.pixi.PixiEvent;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

/**
 * Кнопка.
 * Может содержать текст и/или картинку.
 * 
 * @event Event.PRESS               Нажатие на кнопку. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * @event Event.CLICK               Клик по кнопке. Не путайте с событиями PixiJS. Это событие не диспетчерезируется, если кнопка была выключена: `enabled=false`.
 * @event Event.DOUBLE_CLICK        Двойной клик по кнопке. Необходимо отдельно включить в настройках кнопки: `Button.dblClick.enabled = true`.
 * @event Event.STATE               Состояние кнопки изменено.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class Button extends Component
{
    /**
     * Тип компонента `Button`.
     */
    static public inline var TYPE:String = "Button";

    // Приват
    private var history:Dynamic = {};
    private var isHover:Bool = false;
    private var isPress:Bool = false;
    private var autopressTimeout:Int = 0;
    private var autopressInterval:Int = 0;

    /**
     * Создать кнопку.
     */
    public function new() {
        super();
        
        this.componentType = TYPE;
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
        if (!isActualInput(e))
            return;

        isHover = true;
        updateState();
    }
    private function onRollOut(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;
        
        // Автонажатие:
        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
        }

        isHover = false;
        updateState();
    }
    private function onDown(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        e.stopPropagation();

        isPress = true;
        updateState();

        // Автонажатие:
        if (autopress.enabled && autopressInterval == 0 && autopressTimeout == 0) {
            autopressTimeout = Browser.window.setTimeout(function(){
                if (autopressInterval == 0) {
                    autopressInterval = Browser.window.setInterval(function(){
                        Event.fire(Event.PRESS, this);
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
                Event.fire(Event.PRESS, this);
                return;
            }

            var dx = pre.x - item.x;
            var dy = pre.y - item.y;
            if (Math.abs(dx*dx + dy*dy) > dblClick.dist * dblClick.dist) {
                history[e.data.identifier] = item;
                Event.fire(Event.PRESS, this);
                return;
            }

            history[e.data.identifier] = null;
            Event.fire(Event.PRESS, this);
            Event.fire(Event.DOUBLE_CLICK, this);
            return;
        }
        Event.fire(Event.PRESS, this);
    }
    private function onUp(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;
        
        // Автонажатие:
        if (autopressInterval > 0) {
            Browser.window.clearInterval(autopressInterval);
            autopressInterval = 0;
        }
        if (autopressTimeout > 0) {
            Browser.window.clearTimeout(autopressTimeout);
            autopressTimeout = 0;
        }

        if (isPress) {
            isPress = false;
            Event.fire(Event.CLICK, this);
        }
        
        updateState();
    }
    private function onUpOutside(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        isPress = false;
        updateState();

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
            buttonMode = false;
            interactive = false;
        }

        super.set_enabled(value);
        updateState();
        return value;
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
     * Изменяется автоматически при взаимодействии пользователя с компонентом.
     * Используется как индикатор для отображения необходимых текстур.
     * 
     * По умолчанию: `ButtonState.NORMAL`. (Обычно есостояние)
     * 
     * @event Event.STATE  Посылается в случае изменения состояния.
     */
    public var state(default, null):ButtonState = ButtonState.NORMAL;

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
     * Обновить состояние кнопки.
     * Интерпретирует текущее состояние компонента и записывает его в свойство: `state`.
     * @event Event.STATE - Отправляется в случае изменения значения: `state`.
     */
    private function updateState():Void {
        var v = state;
        if (enabled) {
            if (isPress)        v = ButtonState.PRESS;
            else if (isHover)   v = ButtonState.HOVER;
            else                v = ButtonState.NORMAL;
        }
        else {
            v = ButtonState.DISABLED;
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
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        Utils.destroySkin(label, options);
        Utils.destroySkin(labelHover, options);
        Utils.destroySkin(labelPress, options);
        Utils.destroySkin(labelDisable, options);
        Utils.destroySkin(ico, options);
        Utils.destroySkin(icoHover, options);
        Utils.destroySkin(icoPress, options);
        Utils.destroySkin(icoDisable, options);
        Utils.destroySkin(skinBgHover, options);
        Utils.destroySkin(skinBgPress, options);

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



    ////////////////////////////////
    //   ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ   //
    ////////////////////////////////

    /**
     * Установка значения свойству text указанного компонента.
     * 
     * Геттеры и сеттеры в хаксе конченные, без приведения к типу они
     * нихрена не вызываются! Поэтому этот метод существует.
     * 
     * @param label Компонент для присвоения.
     * @param text Новый текст.
     */
    public static inline function setText(button:Button, text:String):Void {
        button.text = text;
    }

    /**
     * Отображение слоёв в заданном порядке.
     * Этом метод используется для изменения порядка отображения слоёв и их показа.
     * @param skins Все скины, учавствующие в отображении. (В порядке отображения)
     * @param bt Настраиваемая кнопка.
     */
    static public function showLayers(skins:Array<Container>, bt:Button):Void {
        
        // Настройка слоёв.
        // Базовые скины, если не будет указано иное:
        var bg:Container    = bt.skinBg;
        var ico:Container   = bt.ico;
        var label:Label     = bt.label;
        
        // Конкретные скины:
        if (Utils.eq(bt.state, ButtonState.HOVER)) {
            if (bt.skinBgHover != null)      bg = bt.skinBgHover;
            if (bt.labelHover != null)       label = bt.labelHover;
            if (bt.icoHover != null)         ico = bt.icoHover;
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) {
            if (bt.skinBgPress != null)      bg = bt.skinBgPress;
            if (bt.labelPress != null)       label = bt.labelPress;
            if (bt.icoPress != null)         ico = bt.icoPress;
        }
        else if (Utils.eq(bt.state, ButtonState.DISABLED)) {
            if (bt.skinBgDisable != null)    bg = bt.skinBgDisable;
            if (bt.labelDisable != null)     label = bt.labelDisable;
            if (bt.icoDisable != null)       ico = bt.icoDisable;
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
    static public function basePos(bt:Button) {
        Utils.size(bt.skinBg, bt.w, bt.h);
        Utils.size(bt.skinBgHover, bt.w, bt.h);
        Utils.size(bt.skinBgPress, bt.w, bt.h);
        Utils.size(bt.skinBgDisable, bt.w, bt.h);

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

        // Состояние:
        if (Utils.eq(bt.state, ButtonState.DISABLED)) { // Выключено
            if (Utils.noeq(bt.icoDisable, null))        p.ico = bt.icoDisable;
            if (Utils.noeq(bt.labelDisable, null))      p.label = bt.labelDisable;
            if (Utils.noeq(bt.paddingDisable, null)) {
                if (bt.paddingDisable.top != null)      p.pt = bt.paddingDisable.top;
                if (bt.paddingDisable.left != null)     p.pl = bt.paddingDisable.left;
                if (bt.paddingDisable.right != null)    p.pr = bt.paddingDisable.right;
                if (bt.paddingDisable.bottom != null)   p.pb = bt.paddingDisable.bottom;
            }
        }
        else if (Utils.eq(bt.state, ButtonState.HOVER)) { // Наведение
            if (Utils.noeq(bt.icoHover, null))          p.ico = bt.icoHover;
            if (Utils.noeq(bt.labelHover, null))        p.label = bt.labelHover;
            if (Utils.noeq(bt.paddingHover, null)) {
                if (bt.paddingHover.top != null)        p.pt = bt.paddingHover.top;
                if (bt.paddingHover.left != null)       p.pl = bt.paddingHover.left;
                if (bt.paddingHover.right != null)      p.pr = bt.paddingHover.right;
                if (bt.paddingHover.bottom != null)     p.pb = bt.paddingHover.bottom;
            }
        }
        else if (Utils.eq(bt.state, ButtonState.PRESS)) { // Нажатие
            if (Utils.noeq(bt.icoPress, null))          p.ico = bt.icoPress;
            if (Utils.noeq(bt.labelPress, null))        p.label = bt.labelPress;
            if (Utils.noeq(bt.paddingPress, null)) {
                if (bt.paddingPress.top != null)        p.pt = bt.paddingPress.top;
                if (bt.paddingPress.left != null)       p.pl = bt.paddingPress.left;
                if (bt.paddingPress.right != null)      p.pr = bt.paddingPress.right;
                if (bt.paddingPress.bottom != null)     p.pb = bt.paddingPress.bottom;
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
    static public var icoTop:SizeUpdater<Button> = function(bt) {
        showLayers([
            bt.skinBg,
            bt.skinBgHover,
            bt.skinBgPress,
            bt.skinBgDisable,

            bt.label,
            bt.labelHover,
            bt.labelPress,
            bt.labelDisable,

            bt.ico,
            bt.icoHover,
            bt.icoPress,
            bt.icoDisable,
        ], bt);
    }

    /**
     * Иконка под текстом.
     * Используется по умолчанию.
     */
    static public var icoDown:SizeUpdater<Button> = function(bt) {
        showLayers([
            bt.skinBg,
            bt.skinBgHover,
            bt.skinBgPress,
            bt.skinBgDisable,

            bt.ico,
            bt.icoHover,
            bt.icoPress,
            bt.icoDisable,

            bt.label,
            bt.labelHover,
            bt.labelPress,
            bt.labelDisable,
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
    static public var pos1:SizeUpdater<Button> = function(bt) {
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
    static public var pos2:SizeUpdater<Button> = function(bt) {
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
    static public var pos3:SizeUpdater<Button> = function(bt) {
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
    static public var pos4:SizeUpdater<Button> = function(bt) {
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
    static public var pos5:SizeUpdater<Button> = function(bt) {
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
    static public var pos6:SizeUpdater<Button> = function(bt) {
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
    static public var pos7:SizeUpdater<Button> = function(bt) {
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
    static public var pos8:SizeUpdater<Button> = function(bt) {
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
    static public var pos9:SizeUpdater<Button> = function(bt) {
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
 * Состояние кнопки.
 * Описывает все возможные состояния в которых может находиться кнопка.
 */
@:enum abstract ButtonState(Int) to Int
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