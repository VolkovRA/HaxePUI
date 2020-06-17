package pui.ui;

import pui.events.Event;
import pui.ui.Component;
import pui.pixi.PixiEvent;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.interaction.InteractionEvent;
import haxe.extern.EitherType;

/**
 * Флажок.
 * 
 * Флажок используется для выбора или отмены выбора элементов действий.
 * Его можно использовать для одного элемента или списка из нескольких элементов с возможностью выбора.
 * Элемент управления предусматривает три состояния выделения: "не выбрано", "выбрано" и "не определено".
 * Состояние "не определено" используется, когда в подсписке вариантов есть одновременно состояния "не выбрано" и "выбрано".
 * 
 * @event Event.STATE               Диспетчерезируется при изменении значения: `CheckBox.state`.
 * @event Event.CHANGE              Диспетчерезируется при изменении значения: `CheckBox.value`.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class CheckBox extends Component
{
    /**
     * Тип компонента `CheckBox`.
     */
    static public inline var TYPE:String = "CheckBox";

    // Приват
    private var isHover:Bool = false;
    private var isPress:Bool = false;

    /**
     * Создать флажок.
     */
    public function new() {
        super();

        this.componentType = TYPE;
        this.buttonMode = true;
        this.interactive = true;

        Utils.set(this.updateLayers, CheckBox.defaultLayers);
        Utils.set(this.updateSize, CheckBox.defaultSize);

        on(PixiEvent.POINTER_OVER, onRollOver);
        on(PixiEvent.POINTER_OUT, onRollOut);
        on(PixiEvent.POINTER_DOWN, onDown);
        on(PixiEvent.POINTER_UP, onUp);
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

        isHover = false;
        isPress = false;
        updateState();
    }
    private function onDown(e:InteractionEvent):Void {
        if (!isActualInput(e))
            return;

        e.stopPropagation();

        isPress = true;
        updateState();
    }
    private function onUp(e:InteractionEvent):Void {
        if (!isActualInput(e) || !isPress)
            return;

        e.stopPropagation();
        isPress = false;
        
        if (value)
            value = false;
        else // <-- false и null устанавливаются в true
            value = true;
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        super.set_enabled(value);
        updateState();
        return value;
    }

    /**
     * Значение чекбокса.
     * 
     * Это значение может находиться только в **трёх** состояниях:
     * - Выбрано: `true`.
     * - Не выбрано: `false`.
     * - Не определено: `null`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения слоёв.
     * 
     * По умолчанию: `false` (Не выбрано)
     * 
     * @event Event.CHANGE  Посылается в случае установки **нового** значения.
     */
    public var value(default, set):Null<Bool> = false;
    function set_value(value2:Null<Bool>):Null<Bool> {
        var v:Null<Bool> = false;
        if (value2)
            v = true;
        else if (Utils.eq(value2, null))
            v = null;
        
        if (Utils.eq(v, value))
            return value2;

        value = v;
        
        update(false, Component.UPDATE_LAYERS);
        Event.fire(Event.CHANGE, this);
        updateState();
        return value2;
    }

    /**
     * Состояние флажка.
     * 
     * Изменяется автоматически при взаимодействии пользователя с компонентом.
     * Используется как индикатор для отображения необходимых текстур.
     * 
     * По умолчанию: `false` (Флажок не установлен)
     * 
     * @event Event.STATE  Посылается в случае изменения состояния.
     */
    public var state(default, null):CheckBoxState = CheckBoxState.FALSE;



    ///////////////
    //   СКИНЫ   //
    ///////////////

    /**
     * Скин фона в состоянии: `CheckBoxState.FALSE_HOVER`.
     * 
     * Если не задано, используется скин: `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
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
     * Скин фона в состоянии: `CheckBoxState.FALSE_PRESS`.
     * 
     * Если не задано, используется скин: `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
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
     * Скин фона в состоянии: `CheckBoxState.TRUE`.
     * 
     * Если не задано, используется скин: `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgChecked(default, set):Container = null;
    function set_skinBgChecked(value:Container):Container {
        if (Utils.eq(value, skinBgChecked))
            return value;
        
        Utils.hide(this, skinBgChecked);
        skinBgChecked = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.TRUE_HOVER`.
     * 
     * Если не задано, используется скин: `skinBgChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgCheckedHover(default, set):Container = null;
    function set_skinBgCheckedHover(value:Container):Container {
        if (Utils.eq(value, skinBgCheckedHover))
            return value;
        
        Utils.hide(this, skinBgCheckedHover);
        skinBgCheckedHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.TRUE_PRESS`.
     * 
     * Если не задано, используется скин: `skinBgChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgCheckedPress(default, set):Container = null;
    function set_skinBgCheckedPress(value:Container):Container {
        if (Utils.eq(value, skinBgCheckedPress))
            return value;
        
        Utils.hide(this, skinBgCheckedPress);
        skinBgCheckedPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.DISABLED_TRUE`.
     * 
     * Если не задано, используется скин: `skinBgChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgCheckedDisable(default, set):Container = null;
    function set_skinBgCheckedDisable(value:Container):Container {
        if (Utils.eq(value, skinBgCheckedDisable))
            return value;
        
        Utils.hide(this, skinBgCheckedDisable);
        skinBgCheckedDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.NULL`.
     * 
     * Если не задано, используется скин: `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgUnknown(default, set):Container = null;
    function set_skinBgUnknown(value:Container):Container {
        if (Utils.eq(value, skinBgUnknown))
            return value;
        
        Utils.hide(this, skinBgUnknown);
        skinBgUnknown = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.NULL_HOVER`.
     * 
     * Если не задано, используется скин: `skinBgUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgUnknownHover(default, set):Container = null;
    function set_skinBgUnknownHover(value:Container):Container {
        if (Utils.eq(value, skinBgUnknownHover))
            return value;
        
        Utils.hide(this, skinBgUnknownHover);
        skinBgUnknownHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.NULL_PRESS`.
     * 
     * Если не задано, используется скин: `skinBgUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgUnknownPress(default, set):Container = null;
    function set_skinBgUnknownPress(value:Container):Container {
        if (Utils.eq(value, skinBgUnknownPress))
            return value;
        
        Utils.hide(this, skinBgUnknownPress);
        skinBgUnknownPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин фона в состоянии: `CheckBoxState.DISABLED_NULL`.
     * 
     * Если не задано, используется скин: `skinBgUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgUnknownDisable(default, set):Container = null;
    function set_skinBgUnknownDisable(value:Container):Container {
        if (Utils.eq(value, skinBgUnknownDisable))
            return value;
        
        Utils.hide(this, skinBgUnknownDisable);
        skinBgUnknownDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.FALSE`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIco(default, set):Container = null;
    function set_skinIco(value:Container):Container {
        if (Utils.eq(value, skinIco))
            return value;
        
        Utils.hide(this, skinIco);
        skinIco = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.FALSE_HOVER`.
     * 
     * Если не задано, используется скин: `skinIco`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoHover(default, set):Container = null;
    function set_skinIcoHover(value:Container):Container {
        if (Utils.eq(value, skinIcoHover))
            return value;
        
        Utils.hide(this, skinIcoHover);
        skinIcoHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.FALSE_PRESS`.
     * 
     * Если не задано, используется скин: `skinIco`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoPress(default, set):Container = null;
    function set_skinIcoPress(value:Container):Container {
        if (Utils.eq(value, skinIcoPress))
            return value;
        
        Utils.hide(this, skinIcoPress);
        skinIcoPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.DISABLED_FALSE`.
     * 
     * Если не задано, используется скин: `skinIco`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoDisable(default, set):Container = null;
    function set_skinIcoDisable(value:Container):Container {
        if (Utils.eq(value, skinIcoDisable))
            return value;
        
        Utils.hide(this, skinIcoDisable);
        skinIcoDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.TRUE`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoChecked(default, set):Container = null;
    function set_skinIcoChecked(value:Container):Container {
        if (Utils.eq(value, skinIcoChecked))
            return value;
        
        Utils.hide(this, skinIcoChecked);
        skinIcoChecked = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }
    
    /**
     * Скин флажка в состоянии: `CheckBoxState.TRUE_HOVER`.
     * 
     * Если не задано, используется скин: `skinIcoChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoCheckedHover(default, set):Container = null;
    function set_skinIcoCheckedHover(value:Container):Container {
        if (Utils.eq(value, skinIcoCheckedHover))
            return value;
        
        Utils.hide(this, skinIcoCheckedHover);
        skinIcoCheckedHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.TRUE_PRESS`.
     * 
     * Если не задано, используется скин: `skinIcoChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoCheckedPress(default, set):Container = null;
    function set_skinIcoCheckedPress(value:Container):Container {
        if (Utils.eq(value, skinIcoCheckedPress))
            return value;

        Utils.hide(this, skinIcoCheckedPress);
        skinIcoCheckedPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.DISABLED_TRUE`.
     * 
     * Если не задано, используется скин: `skinIcoChecked`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoCheckedDisable(default, set):Container = null;
    function set_skinIcoCheckedDisable(value:Container):Container {
        if (Utils.eq(value, skinIcoCheckedDisable))
            return value;
        
        Utils.hide(this, skinIcoCheckedDisable);
        skinIcoCheckedDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.NULL`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoUnknown(default, set):Container = null;
    function set_skinIcoUnknown(value:Container):Container {
        if (Utils.eq(value, skinIcoUnknown))
            return value;
        
        Utils.hide(this, skinIcoUnknown);
        skinIcoUnknown = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.NULL_HOVER`.
     * 
     * Если не задано, используется скин: `skinIcoUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoUnknownHover(default, set):Container = null;
    function set_skinIcoUnknownHover(value:Container):Container {
        if (Utils.eq(value, skinIcoUnknownHover))
            return value;
        
        Utils.hide(this, skinIcoUnknownHover);
        skinIcoUnknownHover = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.NULL_PRESS`.
     * 
     * Если не задано, используется скин: `skinIcoUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoUnknownPress(default, set):Container = null;
    function set_skinIcoUnknownPress(value:Container):Container {
        if (Utils.eq(value, skinIcoUnknownPress))
            return value;

        Utils.hide(this, skinIcoUnknownPress);
        skinIcoUnknownPress = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин флажка в состоянии: `CheckBoxState.DISABLED_NULL`.
     * 
     * Если не задано, используется скин: `skinIcoUnknown`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinIcoUnknownDisable(default, set):Container = null;
    function set_skinIcoUnknownDisable(value:Container):Container {
        if (Utils.eq(value, skinIcoUnknownDisable))
            return value;
        
        Utils.hide(this, skinIcoUnknownDisable);
        skinIcoUnknownDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Обновить состояние флажка.
     * Интерпретирует текущее состояние компонента и записывает его в свойство: `state`.
     * 
     * @event Event.STATE - Отправляется в случае изменения значения: `state`.
     */
    private function updateState():Void {
        var v = state;
        if (enabled) {
            if (Utils.eq(value, true)) {
                if (isPress)        v = CheckBoxState.TRUE_PRESS;
                else if (isHover)   v = CheckBoxState.TRUE_HOVER;
                else                v = CheckBoxState.TRUE;
            }
            else if (Utils.eq(value, null)) {
                if (isPress)        v = CheckBoxState.NULL_PRESS;
                else if (isHover)   v = CheckBoxState.NULL_HOVER;
                else                v = CheckBoxState.NULL;
            }
            else {
                if (isPress)        v = CheckBoxState.FALSE_PRESS;
                else if (isHover)   v = CheckBoxState.FALSE_HOVER;
                else                v = CheckBoxState.FALSE;
            }
        }
        else {
            if (Utils.eq(value, true))      v = CheckBoxState.DISABLED_TRUE;
            else if (Utils.eq(value, null)) v = CheckBoxState.DISABLED_NULL;
            else                            v = CheckBoxState.DISABLED_FALSE;
        }

        if (Utils.eq(v, state))
            return;
        
        state = v;
        update(false, Component.UPDATE_LAYERS);
        Event.fire(Event.STATE, this);
    }

    /**
     * Выгрузить флажок.
     */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        Utils.destroySkin(skinBgChecked, options);
        Utils.destroySkin(skinBgCheckedDisable, options);
        Utils.destroySkin(skinBgCheckedHover, options);
        Utils.destroySkin(skinBgCheckedPress, options);
        Utils.destroySkin(skinBgHover, options);
        Utils.destroySkin(skinBgPress, options);
        Utils.destroySkin(skinBgUnknown, options);
        Utils.destroySkin(skinBgUnknownDisable, options);
        Utils.destroySkin(skinBgUnknownHover, options);
        Utils.destroySkin(skinBgUnknownPress, options);
        Utils.destroySkin(skinIco, options);
        Utils.destroySkin(skinIcoChecked, options);
        Utils.destroySkin(skinIcoCheckedDisable, options);
        Utils.destroySkin(skinIcoCheckedHover, options);
        Utils.destroySkin(skinIcoCheckedPress, options);
        Utils.destroySkin(skinIcoDisable, options);
        Utils.destroySkin(skinIcoHover, options);
        Utils.destroySkin(skinIcoPress, options);
        Utils.destroySkin(skinIcoUnknown, options);
        Utils.destroySkin(skinIcoUnknownDisable, options);
        Utils.destroySkin(skinIcoUnknownHover, options);
        Utils.destroySkin(skinIcoUnknownPress, options);

        super.destroy(options);
    }



    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв флажка.
     */
    static public var defaultLayers:LayersUpdater<CheckBox> = function(c) {
        var bg:Container = c.skinBg; // <-- Базовый скин, если не указано иное
        var ico:Container = null;
        var skins:Array<Container> = [ // Все скины, учавствующие в отображении. (В порядке отображения)
            c.skinBg,
            c.skinBgHover,
            c.skinBgPress,
            c.skinBgDisable,

            c.skinBgChecked,
            c.skinBgCheckedHover,
            c.skinBgCheckedPress,
            c.skinBgCheckedDisable,

            c.skinBgUnknown,
            c.skinBgUnknownHover,
            c.skinBgUnknownPress,
            c.skinBgUnknownDisable,

            c.skinIco,
            c.skinIcoHover,
            c.skinIcoPress,
            c.skinIcoDisable,

            c.skinIcoChecked,
            c.skinIcoCheckedHover,
            c.skinIcoCheckedPress,
            c.skinIcoCheckedDisable,

            c.skinIcoUnknown,
            c.skinIcoUnknownHover,
            c.skinIcoUnknownPress,
            c.skinIcoUnknownDisable,
        ];

        // Скины второго порядка: (Если не будут заданы конкретные)
        if (Utils.eq(c.value, true)) {
            if (c.skinBgChecked != null)    bg = c.skinBgChecked;
            if (c.skinIcoChecked != null)   ico = c.skinIcoChecked;
        }
        else if (Utils.eq(c.value, null)) {
            if (c.skinBgUnknown != null)    bg = c.skinBgUnknown;
            if (c.skinIcoUnknown != null)   ico = c.skinIcoUnknown;
        }
        else {
            if (c.skinBg != null)           bg = c.skinBg;
            if (c.skinIco != null)          ico = c.skinIco;
        }

        // Конкретные скины:
        if (Utils.eq(c.state, CheckBoxState.FALSE_HOVER)) {
            if (c.skinBgHover != null)      bg = c.skinBgHover;
            if (c.skinIcoHover != null)     ico = c.skinIcoHover;
        }
        else if (Utils.eq(c.state, CheckBoxState.FALSE_PRESS)) {
            if (c.skinIcoPress != null)     ico = c.skinIcoPress;
            if (c.skinBgPress != null)      bg = c.skinBgPress;
        }
        else if (Utils.eq(c.state, CheckBoxState.DISABLED_FALSE)) {
            if (c.skinIcoDisable != null)   ico = c.skinIcoDisable;
            if (c.skinBgDisable != null)    bg = c.skinBgDisable;
        }

        else if (Utils.eq(c.state, CheckBoxState.TRUE_HOVER)) {
            if (c.skinIcoCheckedHover != null)      ico = c.skinIcoCheckedHover;
            if (c.skinBgCheckedHover != null)       bg = c.skinBgCheckedHover;
        }
        else if (Utils.eq(c.state, CheckBoxState.TRUE_PRESS)) {
            if (c.skinIcoCheckedPress != null)      ico = c.skinIcoCheckedPress;
            if (c.skinBgCheckedPress != null)       bg = c.skinBgCheckedPress;
        }
        else if (Utils.eq(c.state, CheckBoxState.DISABLED_TRUE)) {
            if (c.skinIcoCheckedDisable != null)    ico = c.skinIcoCheckedDisable;
            if (c.skinBgCheckedDisable != null)     bg = c.skinBgCheckedDisable;
        }

        else if (Utils.eq(c.state, CheckBoxState.NULL_HOVER)) {
            if (c.skinIcoUnknownHover != null)      ico = c.skinIcoUnknownHover;
            if (c.skinBgUnknownHover != null)       bg = c.skinBgUnknownHover;
        }
        else if (Utils.eq(c.state, CheckBoxState.NULL_PRESS)) {
            if (c.skinIcoUnknownPress != null)      ico = c.skinIcoUnknownPress;
            if (c.skinBgUnknownPress != null)       bg = c.skinBgUnknownPress;
        }
        else if (Utils.eq(c.state, CheckBoxState.DISABLED_NULL)) {
            if (c.skinIcoUnknownDisable != null)    ico = c.skinIcoUnknownDisable;
            if (c.skinBgUnknownDisable != null)     bg = c.skinBgUnknownDisable;
        }
        
        // Отображение:
        var i = 0;
        var len = skins.length;
        while (i < len) {
            var skin = skins[i++];
            if (skin == null)
                continue;
            
            if (Utils.eq(skin,bg) || Utils.eq(skin,ico)) {
                if (Utils.eq(skin.parent,c))
                    continue;
                else
                    c.addChild(skin);
            }
            else {
                if (Utils.eq(skin.parent,c))
                    c.removeChild(skin);
            }
        }
    }

    /**
     * Обычное позицианирование флажка.
     */
    static public var defaultSize:SizeUpdater<CheckBox> = function(c) {
        Utils.size(c.skinBg, c.w, c.h);
        Utils.size(c.skinBgHover, c.w, c.h);
        Utils.size(c.skinBgPress, c.w, c.h);
        Utils.size(c.skinBgDisable, c.w, c.h);
        Utils.size(c.skinBgChecked, c.w, c.h);
        Utils.size(c.skinBgCheckedDisable, c.w, c.h);
        Utils.size(c.skinBgCheckedHover, c.w, c.h);
        Utils.size(c.skinBgCheckedPress, c.w, c.h);
        Utils.size(c.skinBgUnknown, c.w, c.h);
        Utils.size(c.skinBgUnknownDisable, c.w, c.h);
        Utils.size(c.skinBgUnknownHover, c.w, c.h);
        Utils.size(c.skinBgUnknownPress, c.w, c.h);
    }
}

/**
 * Состояние флажка.
 */
@:enum abstract CheckBoxState(Int) to Int
{
    /**
     * Флажок снят.
     */
    var FALSE = 0;
    /**
     * Флажок снят - наведение.
     */
    var FALSE_HOVER = 1;
    /**
     * Флажок снят - нажатие.
     */
    var FALSE_PRESS = 2;
    /**
     * Флажок снят - выключен.
     */
    var DISABLED_FALSE = 3;

    /**
     * Флажок установлен.
     */
    var TRUE = 10;
    /**
     * Флажок установлен - наведение.
     */
    var TRUE_HOVER = 11;
    /**
     * Флажок установлен - нажатие.
     */
    var TRUE_PRESS = 12;
    /**
     * Флажок установлен - выключен.
     */
    var DISABLED_TRUE = 13;

    /**
     * Флажок не определён.
     */
    var NULL = 20;
    /**
     * Флажок не определён - наведение.
     */
    var NULL_HOVER = 21;
    /**
     * Флажок не определён - нажатие.
     */
    var NULL_PRESS = 22;
    /**
     * Флажок не определён - выключен.
     */
    var DISABLED_NULL = 23;
}