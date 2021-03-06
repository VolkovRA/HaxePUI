package pui.ui;

import haxe.extern.EitherType;
import js.lib.Error;
import pixi.display.Container;
import pixi.display.Graphics;
import pixi.events.InteractionEvent;
import pui.dom.Mouse;
import pui.dom.PointerType;
import pui.events.ComponentEvent;

/**
 * Компонент графического интерфейса пользователя.
 * 
 * Это абстрактный, базовый класс для всех элементов интерфейса.
 * Содержит встроенную систему для накопления изменений и фактического
 * обновления перед началом цикла рендера. (Смотрите свойство: `changes`)
 * 
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class Component extends Container
{
    /**
     * Создать компонент интерфейса.
     */
    public function new() {
        super();
        
        this.componentType = "Component";
        this.componentID = Component.nextID++;
        this.theme = Theme.current;

        Utils.set(this.updateLayers, Component.defaultLayers);
        Utils.set(this.updateSize, Component.defaultSize);
    }



    ///////////////
    //   ФЛАГИ   //
    ///////////////
    
    /**
     * Полное обновление. (`00000001` или `2^0`)
     * Требуется выполнить полное обновление компонента с повторным его скинованием и прочим.
     * 
     * Вызываемые методы:
     *   * `Theme.apply()` - Скинование компонента.
     *   * `Component.updateLayers()` - Обновление списка отображения.
     *   * `Component.updateSize()` - Обновление размеров.
     */
    static public inline var UPDATE_FULL:BitMask = 1;

    /**
     * Изменение списка отображения. (`00000010` или `2^1`)
     * Требуется выполнить только обновление списка отображения компонента.
     * 
     * Вызываемые методы:
     *   * `Component.updateLayers()` - Обновление списка отображения.
     */
    static public inline var UPDATE_LAYERS:BitMask = 2;

    /**
     * Изменение размеров компонента. (`00000100` или `2^2`)
     * Требуется выполнить только обновление размеров компонента.
     * 
     * Вызываемые методы:
     *   * `Component.updateSize()` - Обновление размеров.
     */
    static public inline var UPDATE_SIZE:BitMask = 4;



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Счётчик ID для новых экземпляров `Component`.
     * 
     * Увеличивается на один при каждом создании нового экземпляра класса.
     * Используется для получения уникальных идентификаторов: `Component.componentID`.
     * 
     * Отсчёт начинается с `1`.
     */
    static public var nextID(default, null):Int = 1;

    /**
     * ID Компонента. (read-only)
     * 
     * Уникальный идентификатор среди всех созданных компонентов.
     * Может использоваться для однозначной идентификации этого элемента
     * интерфейса.
     * 
     * Отсчёт начинается с `1`.
     */
    public var componentID(default, null):Int;

    /**
     * Тип компонента. (read-only)
     * 
     * Используется для быстрого определения типа компонента, например,
     * при его скиновании. Пример: `Label`, `Button`, `Scroller` и т.д.
     * 
     * Это значение можно изменять только в конструкторе класса или его
     * подкласса. Оно должно быть **фиксированным** на протяжении всего
     * времени жизни компонента.
     */
    public var componentType(default, null):String;

    /**
     * Компонент инициализирован.
     * 
     * Инициализация компонента - это самый первый вызов его обновления, при котором
     * назначаются текстуры, выполняется позицианирование и обновление списка отображения.
     * При переключении темы оформления это значение сбрасывается в `false` для
     * проведения повторной инициализации.
     * 
     * Вы можете выполнить инициализацию компонента досрочно:
     * ```
     * var bt:Component = new Button();
     * bt.update(true); // Инициализирован!
     * ```
     * 
     * Ожидание автоматической инициализации компонента:
     * ```
     * var bt:Component = new Button();
     * bt.once(ComponentEvent.UPDATED, function(e:ComponentEvent){ trace("Кнопка инициализирована!"); });
     * ```
     * 
     * По умолчанию: `false.`
     */
    public var isInit(default, null):Bool = false;

    /**
     * Номер кадра, в котором последний раз производилось обновление этого компонента.
     * Используется для идентификации того, обновлялся ли этот компонент в текущем цикле рендера или ещё нет.
     * 
     * Управляется классом: `Theme`.
     */
    @:allow(pui.Theme) 
    @:noDoc
    @:noCompletion
    private var themeRenderFrame:Int = 0;

    /**
     * Количество обновление этого компонента в текущем цикле рендера.
     * Используется, что бы ограничить бесконечное зацикливание обновления компонента в одном цикле рендера.
     * 
     * Управляется классом: `Theme`.
     */
    @:allow(pui.Theme) 
    @:noDoc
    @:noCompletion
    private var themeRenderCount:Int = 0;

    /**
     * Индекс позиции компонента в списке обновляемых компонентов цикла рендера.
     * Используется для обеспечения порядка обновления компонентов в том виде, в котором они были добавлены.
     * 
     * Дело в том, что **возможна** ситуация, когда компонент был добавлен для обновления, затем обновлён
     * вручную и снова добавлен в список рендера в рамках всё одного цикла. В этом случае компонент **может**
     * обновиться ранее других, за счёт своего предыдущего добавления. Это свойство исключает это и гарантирует
     * обновление компонента в том порядке, в котором он был повторно добавлен в список на обновление.
     * 
     * Управляется классом: `Theme`.
     */
    @:allow(pui.Theme)
    @:noDoc
    @:noCompletion
    private var themeRenderIndex:Int = 0;

    /**
     * Накопленные изменения. *(Битовая маска)*
     * 
     * Это свойство используется для указания того, какие именно изменения были произведены в
     * компоненте с момента его последнего обновления. Это полезно для оптимизации, когда
     * требуется выполнить только незначительные изменения, вместо его полной перерисовки.
     * 
     * Базовые типы изменений:
     *   * `Theme.apply()` - **Скинование** компонента.
     *   * `Component.updateLayers()` - Обновление **списка отображения**.
     *   * `Component.updateSize()` - **Позицианирование** внутренних элементов.
     * 
     * *пс. Подклассы так же могут иметь собственные типы изменений, для более тонкой оптимизации.*
     * 
     * Значение `0` - указывает на отсутствие изменений. (`00000000 00000000 00000000 00000000`)
     * 
     * Первые 8 битов маски (`11111111`) зарезервированы для использования самим классом `Component`.
     * Последующие биты могут произвольно использоваться наследниками `Component` по своему усмотрению.
     * 
     * По умолчанию: `Component.UPDATE_FULL`. *(Компонент создан и ожидает полной перерисовки)*
     */
    public var changes(default, null):BitMask = 0;

    /**
     * Используемый стиль.
     * 
     * Необходим для кастомизации отображения компонента путём назначения ему конкретного
     * стиля оформления. При изменении стиля компонент будет перерисован перед следующим
     * циклом рендера или при ручном вызове метода: `Component.update(true)`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_FULL` - Для полной перерисовки компонента в соответствии с новым стилем.
     * 
     * Не может быть `null`.
     */
    public var style(default, set):String = "";
    function set_style(value:String):String {
        if (Utils.eq(value, null))
            throw new Error("Стиль компонента не может быть null");
        if (Utils.eq(value, style))
            return value;

        style = value;
        update(false, Component.UPDATE_FULL);
        return value;
    }

    /**
     * Тема оформления.
     * 
     * Каждый компонент обязательно должен быть связан с какой то темой. Тема используется для
     * скинования компонента, а также обеспечивает функциональность обновления компонента при
     * его изменениях. *(см.: `Component.update()`)*
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.FULL_UPDATE` - Для полной перерисовки компонента по новой теме.
     * 
     * Значение по умолчанию: `Theme.current`.
     */
    public var theme(default, set):Theme;
    function set_theme(value:Theme):Theme {
        if (Utils.eq(value, null))
            throw new Error("Тема оформления не может быть null");
        if (Utils.eq(value, theme))
            return value;

        if (inputWheel) {
            theme.removeWheelListener(this);
            value.addWheelListener(this);
        }

        theme = value;
        isInit = false;
        themeRenderFrame = 0;
        themeRenderCount = 0;
        themeRenderIndex = 0;
        update(false, Component.UPDATE_FULL);
        return value;
    }
    
    /**
     * Ширина компонента. (px)
     * 
     * Для указания размеров компонента вы **должны** использовать это значение, а не `width`.
     * - Это отдельное, собственное значение, которое указывает на необходимый размер для компонента.
     * - Это значение фиксированное, оно не меняется само по себе и не зависит от трансформаций объекта.
     * - Это значение прямо не влияет на `width` и наоборот.
     * - Это значение не может быть меньше `0`, быть равным `null`, `NaN` или т.п.
     * - Это значение всегда целочисленно.
     * 
     * Базовое свойство `width` не подходит из-за этих причин:
     *   1. Оно тесно связано с матрицей объекта, на него влияет скалирование и прочие трансформаций.
     *   2. Это динамическое значение, которое может в любой момент времени измениться.
     *   3. Значение ширины компонента должно использоваться как декларативное.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования из-за изменения размеров.
     * 
     * По умолчанию: `0`.
     */
    public var w(default, set):Float = 0;
    function set_w(value:Float):Float {
        var v = Math.floor(value);
        if (Utils.eq(v, w))
            return value;
        
        if (v > 0)
            w = v;
        else
            w = 0;

        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Высота компонента. (px)
     * 
     * Для указания размеров компонента вы **должны** использовать это значение, а не `height`.
     * - Это отдельное, собственное значение, которое указывает на необходимый размер для компонента.
     * - Это значение фиксированное, оно не меняется само по себе и не зависит от трансформаций объекта.
     * - Это значение прямо не влияет на `height` и наоборот.
     * - Это значение не может быть меньше `0`, быть равным `null`, `NaN` или т.п.  
     * - Это значение всегда целочисленно.
     * 
     * Базовое свойство `height` не подходит из-за этих причин:
     *   1. Оно тесно связано с матрицей объекта, на него влияет скалирование и прочие трансформаций.
     *   2. Это динамическое значение, которое может в любой момент времени измениться.
     *   3. Значение высоты компонента должно использоваться как декларативное.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования из-за изменения размеров.
     * 
     * По умолчанию: `0`.
     */
    public var h(default, set):Float = 0;
    function set_h(value:Float):Float {
        var v = Math.floor(value);
        if (Utils.eq(v, h))
            return value;
        
        if (v > 0)
            h = v;
        else
            h = 0;

        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Активность компонента.
     * 
     * В выключенном состоянии компонент может не отправлять некоторые события
     * взаимодействия с пользователем. Это зависит от конкретного типа компонента.
     * Так же выключенный компонент может иметь собственное оформление.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона выключенного состояния.
     * - `Component.UPDATE_SIZE` - Для обновления позицианирования.
     * 
     * По умолчанию: `true`.
     */
    public var enabled(default, set):Bool = true;
    function set_enabled(value:Bool):Bool {
        if (Utils.eq(value, enabled))
            return value;
        
        enabled = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Внутренние отступы.
     * 
     * Это свойство похоже на аналогичное в css, с помощью которого вы можете
     * задать отступы для внутреннего содержимого элемента от его краёв. Не
     * все компоненты обязательно реализуют это поведение. Для того, что бы
     * изменения вступили в силу, вы можете переназначить объект в это свойство
     * или вызвать метод `update()` вручную.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`. (Отступы не заданы)
     */
    public var padding(default, set):Offset = null;
    function set_padding(value:Offset):Offset {
        padding = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Ввод только с основного устройства.
     * 
     * Основное устройство - это мышь, первое касание на сенсорном устройстве или т.п.
     * Это значение не влияет на работу стандартных событий PixiJS, но может использоваться
     * компонентами библиотеки для настройки их ввода и реагирования.
     * - Если `true` - Компонент будет реагировать только на ввод с основного устройства. (Мышь)
     * - Если `false` - Компонент будет реагировать на ввод с любого устройства.
     * 
     * По умолчанию: `true`
     * 
     * @see PointerEvent.isPrimary: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/isPrimary
     */
    public var inputPrimary:Bool = true;

    /**
     * Ввод с клавишь мыши.
     * 
     * Позволяет установить, на какие кнопки мыши будет реагировать компонент.
     * - Если `null` или пустой массив - компонент реагирует на любые клавишы мыши.
     * 
     * По умолчанию: `[Mouse.MAIN]` (Только главная кнопка мыши)
     */
    public var inputMouse:Array<MouseKey> = [Mouse.MAIN];

    /**
     * Ввод колёсиком мыши.
     * 
     * Позволяет подключить компонент к получению событий колёсика мыши: `pui.events.WheelEvent`.
     * Если задать `true`, компонент будет добавлен в список получателей данного события.
     * 
     * Условия для получения события:
     * 1. Свойство `inputWheel` задано в `true`.
     * 2. Свойство `enabled` задано в `true`.
     * 3. Курсор мыши находится в области компонента: `x`, `y`, `w`, `h`.
     * 4. Компонент находится на сцене. (Он или один из родителей находится на корневом stage)
     * 5. Более глубокие компоненты, получившие это событие не отменили его всплытие. (См.: `WheelEvent.bubbling`)
     * 
     * По умолчанию: `false` (Выключено) 
     */
    public var inputWheel(default, set):Bool = false;
    function set_inputWheel(value:Bool):Bool {
        if (Utils.eq(value, inputWheel))
            return value;

        if (value)
            theme.addWheelListener(this);
        else
            theme.removeWheelListener(this);

        inputWheel = value;

        return value;
    }

    /**
     * Скин заднего фона.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона.
     * 
     * По умолчанию: `null`.
     */
    public var skinBg(default, set):Container = null;
    function set_skinBg(value:Container):Container {
        if (Utils.eq(value, skinBg))
            return value;

        Utils.hide(this, skinBg);
        skinBg = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин заднего фона выключенного состояния.
     * Если значение не задано, используется `skinBg`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для переключения фона выключенного состояния.
     * - `Component.UPDATE_SIZE` - Для позицианирования фона выключенного состояния.
     * 
     * По умолчанию: `null`.
     */
    public var skinBgDisable(default, set):Container = null;
    function set_skinBgDisable(value:Container):Container {
        if (Utils.eq(value, skinBgDisable))
            return value;

        Utils.hide(this, skinBgDisable);
        skinBgDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Функция обновления размеров компонента.
     * 
     * Так как все гуи абсолютно разные, то и их размеры с позицианированием элементов могут быть очень
     * индивидуальным делом, особенно в играх. Поэтому, библиотека предоставляет API для назначения
     * собственных функций изменения рамзеров и позицианирования элементов.
     * 
     * *Каждый компонент библиотеки предоставляет несколько готовых функций ресайза на выбор.*
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для ресайза компонента новым способом.
     * 
     * По умолчанию: `Component.updateSizeDefault`.
     */
    public var updateSize(default, set):SizeUpdater<Dynamic> = Component.defaultSize;
    function set_updateSize(value:SizeUpdater<Dynamic>):SizeUpdater<Dynamic> {
        if (Utils.eq(value, updateSize))
            return value;
        if (Utils.eq(value, null))
            throw new Error("Функция обновления размеров не может быть null");

        updateSize = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Функция обновления списка отображения компонента.
     * 
     * Так как все гуи абсолютно разные, то и список отображения может быть очень индивидуальным делом,
     * особенно в играх. Поэтому, библиотека предоставляет API для назначения собственных функций
     * управления списком отображения для каждого компонента. 
     * 
     * *Каждый компонент библиотеки предоставляет несколько готовых функций управления списком на выбор.*
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для отображения слоёв по новому режиму.
     * 
     * По умолчанию: `Component.updateLayersDefault`.
     */
    public var updateLayers(default, set):LayersUpdater<Dynamic> = Component.defaultLayers;
    function set_updateLayers(value:LayersUpdater<Dynamic>):LayersUpdater<Dynamic> {
        if (Utils.eq(value, updateLayers))
            return value;
        if (Utils.eq(value, null))
            throw new Error("Функция обновления списка отображения не может быть null");

        updateLayers = value;
        update(false, Component.UPDATE_LAYERS);
        return value;
    }

    /**
     * Режим отладки.
     * 
     * Если задан, при обновлении компонента рисуется красный, прозрачный фон сверху,
     * указываюший размеры `w` и `h`. Такая необходимость возникает довольно часто на
     * этапе вёрстки и отладки интерфейса. Вынесено в отдельный флаг для быстрого включения.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления дебагового фона.
     * - `Component.UPDATE_SIZE` - Для позицианирования.
     * 
     * По умолчанию: `false`.
     */
    public var debug(default, set):Bool = false;
    function set_debug(value:Bool):Bool {
        if (Utils.eq(value, debug))
            return value;

        debug = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Дебаговый скин.
     * 
     * Контролируется автоматически через свойство: `Component.debug` и
     * внутренний метод: `drawDebugSkin()`.
     * Вы не должны управлять этим скином через это свойство.
     * 
     * По умолчанию: `null`.
     */
    private var skinDebug(default, null):Graphics = null;



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Обновить компонент.
     * 
     * Обновляет компонент и его содержимое, в зависимости от накопленных изменений в поле `changes`.
     * По умолчанию этот метод регистрирует **необходимость** обновления перед следующим циклом
     * рендера. Вы можете передать флаг `force=true`, чтобы компонент был обновлён **мгновенно**.
     * 
     * Вы можете предварительно накапливать изменения, а затем обновить компонент за один вызов:
     * ```
     * var component:Component = new Button();
     * component.update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE); // Сразу два флага
     * component.update(true); // Если не вызвать, компонент обновится автоматически перед началом следующего цикла рендера
     * ```
     * @param force Выполнить обновление **сейчас**.
     * @param flag Тип изменений в компоненте. (Флаг добавляется к уже имеющимся изменениям в поле `Component.changes`)
     */
    public function update(force:Bool = false, flag:BitMask = 0):Void {
        if (force) {
            changes = changes | flag;

            if (Utils.eq(changes, 0))
                return;

            onComponentUpdate();
        }
        else {
            if (Utils.eq(flag, 0))
                return;
            if (Utils.eq(changes, 0))
                theme.addUpdate(this);

            changes = changes | flag;
        }
    }

    /**
     * Обновить компонент в следующем цикле рендера.
     * 
     * Этот метод удобен для создания анимации. Если во время обновления компонента
     * вы вызовете метод `update()`, компонент обновится в **этом же** цикле рендера.
     * Этот метод позволяет зарегистрировать компонент для обновления в **следующем**
     * цикле.
     * 
     * В других случаях вызов аналогичен: `update(false);`
     * 
     * @param flag Тип изменений в компоненте. (Флаг добавляется к уже имеющимся изменениям в поле `Component.changes`)
     */
    public function updateNext(flag:BitMask = 0):Void {
        theme.addUpdateNext(this, flag);
    }

    /**
     * Функция фактического обновления компонента.
     * 
     * Точки вызова:
     * - Через внешнее API, при вызове метода: `Component.update(true)`.
     * - Автоматически, перед началом следующего цикла рендера из темы, которую использует этот компонент.
     * 
     * Функция может быть переопределена подклассом для реализации собственной логики.
     * В конце обновления не забудьте сбросить флаг изменений: `Component.changes=0`.
     */
    @:allow(pui.Theme)
    private function onComponentUpdate():Void {
        var e = ComponentEvent.get(ComponentEvent.UPDATED, this);
        e.changes = changes;
        
        // Обновление:
        if (Utils.flagsAND(changes, Component.UPDATE_FULL)) {
            theme.apply(this);
            
            updateLayers(this);
            updateSize(this);
        }
        else {
            if (Utils.flagsAND(changes, Component.UPDATE_LAYERS))
                updateLayers(this);
            if (Utils.flagsAND(changes, Component.UPDATE_SIZE))
                updateSize(this);
        }

        // Дебаговый фон:
        if (debug)
            drawDebugSkin();

        // Завершение и события:
        changes = 0;
        isInit = true;
        
        emit(ComponentEvent.UPDATED, e);
        ComponentEvent.store(e);
    }

    /**
     * Отрисовка дебагового фона.
     * Создаёт (если отсутствует) дебаговый скин: `debugSkin`
     * и рисует в него граници компонента.
     */
    private function drawDebugSkin():Void {
        if (Utils.eq(skinDebug, null))
            skinDebug = new Graphics();

        addChild(skinDebug);
        skinDebug.clear();

        // Внутренний отступ:
        if (padding != null) {
            skinDebug.beginFill(0x00ff00, 0.2); // bg
            skinDebug.drawRect(0, 0, w, padding.top);
            skinDebug.drawRect(0, h, w, -padding.bottom);
            skinDebug.drawRect(0, 0, padding.left, h);
            skinDebug.drawRect(w, 0, -padding.right, h);
        }

        // Крестик и фон:
        skinDebug.beginFill(0xff0000, 0.2); // bg
        skinDebug.drawRect(0, 0, w, h);
        skinDebug.beginFill(0xff0000, 1.0);
        skinDebug.drawRect(-2, 0, 5, 1); // cross x
        skinDebug.drawRect(0, -2, 1, 5); // cross y
        skinDebug.beginFill(0xff0000, 0.5);
        Utils.dwarBorder(skinDebug, 0, 0, w, h);
        skinDebug.beginFill(0xff0000, 0.8);
        Utils.drawText(skinDebug, w + "x" + h, 3, 3);
    }

    /**
     * Проверить событие ввода на актуальность.
     * - Возвращает `true`, если компонент **может** обрабатывать это событие.
     * - Возвращает `false`, если компонент **не должен** обрабатывать это событие.
     * 
     * Компонент никогда не должен обрабатывать события ввода, если:
     * 1. Компонент выключен: `enabled=false`.
     * 2. Ввод не с основного устройства при заданной настройке: `inputPrimary=true`.
     * 3. Ввод мышкой не соответствует разрешённым клавишам: `inputMouse=[]`.
     * 
     * Данный метод может быть полезен для подклассов, чтобы не писать одни
     * одинаковые проверки несколько раз.
     * 
     * @param e Событие ввода.
     * @return Результат проверки.
     */
    private function isActualInput(e:InteractionEvent):Bool {
        if (    !enabled || 
                (inputPrimary && !e.data.isPrimary) ||
                (Utils.eq(e.data.pointerType, PointerType.MOUSE) && e.data.button > -1 && inputMouse != null && inputMouse.indexOf(e.data.button) == -1)
        )
            return false;
        
        return true;
    }

    /**
     * Получить строковое представление этого компонента.
     * @return Возвращает строковое представление этого компонента.
     */
    @:keep
    public function toString():String {
        return '[' + componentType + componentID + ' style="' + style + '"]';
    }

	/**
     * Уничтожить компонент.
     * 
     * Удаляет все ссылки на скины и тему, удаляет все слушатели и вызывает `destroy()` суперкласса.
     * Вы не должны использовать компонент после вызова этого метода.
     * 
     * @see https://pixijs.download/dev/docs/PIXI.Container.html#destroy
     */
    @:keep
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        Utils.destroySkin(skinBg, options);
        Utils.destroySkin(skinBgDisable, options);
        Utils.destroySkin(skinDebug, options);

        if (inputWheel)
            theme.removeWheelListener(this);

        Utils.delete(changes);
        Utils.delete(theme);
        Utils.delete(updateLayers);
        Utils.delete(updateSize);

        super.destroy(options);
    }



    /////////////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ И СЛОИ   //
    /////////////////////////////////

    /**
     * Базовое обновление списка отображения компонента.
     */
    static public var defaultLayers:LayersUpdater<Component> = function(component) {
        if (component.enabled) {
            Utils.show(component, component.skinBg);
            Utils.hide(component, component.skinBgDisable);
        }
        else {
            if (Utils.eq(component.skinBgDisable, null)) {
                Utils.show(component, component.skinBg);
                //Utils.hide(component, component.skinBgDisable);
            }
            else {
                Utils.hide(component, component.skinBg);
                Utils.show(component, component.skinBgDisable);
            }
        }
    }

    /**
     * Базовое обновление размеров компонента.
     */
    static public var defaultSize:SizeUpdater<Component> = function(component) {
        Utils.size(component.skinBg, component.w, component.h);
        Utils.size(component.skinBgDisable, component.w, component.h);
    }
}

/**
 * Функция обновления списка отображения компонента.
 * @see Управление списком отображения: `Component.updateLayers`
 */
typedef LayersUpdater<T:Component> = T->Void;

/**
 * Функция обновления размеров компонента.
 * @see Позицианирование элементов: `Component.updateSize`
 */
typedef SizeUpdater<T:Component> = T->Void;