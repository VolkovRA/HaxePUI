package pui;

import js.lib.Error;
import haxe.extern.EitherType;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.graphics.Graphics;

/**
 * Компонент графического интерфейса пользователя.
 * 
 * Это абстрактный, базовый класс для всех элементов интерфейса.
 * Содержит встроенную систему для накопления изменений и фактического
 * обновления перед началом цикла рендера. (Смотрите свойство: `changes`)
 * 
 * События:
 * - `UIEvent.UPDATE` - Компонент обновился: `Component->changes->Void`. (Передаёт старые изменения)
 * - *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class Component extends Container
{
    /**
     * Создать компонент интерфейса.
     * @param type Тип компонента.
     */
    public function new(type:String) {
        super();
        
        this.componentID = Component.nextID++;
        this.theme = Theme.current;
        this.componentType = type;

        Utils.set(this.updateLayers, Component.updateLayersDefault);
        Utils.set(this.updateSize, Component.updateSizeDefault);
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
     * ID Компонента.
     * 
     * Уникальный идентификатор среди всех созданных компонентов.
     * Может использоваться для однозначной идентификации этого элемента интерфейса.
     * 
     * Отсчёт начинается с `1`.
     */
    public var componentID(default, null):Int;

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
     * bt.once(UIEvent.UPDATE, function(component:Component){ trace("Кнопка инициализирована!"); });
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
     * Тип компонента. (read-only)
     * 
     * Используется для быстрого определения типа компонента при его скиновании. Пример: `Label`, `Button`.
     * 
     * Это свойство **должно** быть назначено расширяющим классом, реализующим конкретный компонент интерфейса.
     */
    public var componentType(default, null):String;

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
     *   3. Это значение невозможно переопределить для добавления нужной логики.
     *   4. Значение ширины компонента должно использоваться как декларативное.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования из-за изменения размеров.
     * 
     * По умолчанию: `0`.
     */
    public var w(default, set):Int = 0;
    function set_w(value:Int):Int {
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
     *   3. Это значение невозможно переопределить для добавления нужной логики.
     *   4. Значение высоты компонента должно использоваться как декларативное.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования из-за изменения размеров.
     * 
     * По умолчанию: `0`.
     */
    public var h(default, set):Int = 0;
    function set_h(value:Int):Int {
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
     * Обратите внимание, что в выключенном состоянии компонент по прежнему будет
     * отправлять базовые события `Event` PixiJS. Функциональность событий `UIEvent`
     * зависит от конкретной реализации типа компонента и может быть отключена.
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
    public var updateSize(default, set):SizeUpdater<Dynamic> = Component.updateSizeDefault;
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
    public var updateLayers(default, set):LayersUpdater<Dynamic> = Component.updateLayersDefault;
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
     * рендера. Вы можете передадите флаг `force=true`, чтобы компонент был обновлён **мгновенно**.
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
        var oldc = changes;
        
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
        emit(UIEvent.UPDATE, this, oldc);
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

        // Крестик и фон:
        skinDebug.clear();
        skinDebug.beginFill(0xff0000, 0.2); // bg
        skinDebug.drawRect(0, 0, w, h);
        skinDebug.beginFill(0xff0000, 1.0);
        skinDebug.drawRect(-2, 0, 5, 1); // cross x
        skinDebug.drawRect(0, -2, 1, 5); // cross y
        skinDebug.beginFill(0xff0000, 0.5);

        // Обводка:
        var i = w;
        while (i-- > 0) {
            if (i % 2 == 0) {
                skinDebug.drawRect(i, 0, 1, 1); // border x top
                skinDebug.drawRect(i, h-1, 1, 1); // border x bottom
            }
        }

        i = h;
        while (i-- > 0) {
            if (i % 2 == 0) {
                skinDebug.drawRect(0, i, 1, 1); // border y top
                skinDebug.drawRect(w-1, i, 1, 1); // border y bottom
            }
        }

        // Надпись размеров:
        skinDebug.beginFill(0xff0000, 0.8);
        PixelsString.draw(skinDebug, w + "x" + h, 3, 3);
    }

    /**
     * Получить строковое представление этого компонента.
     * @return Возвращает строковое представление этого компонента.
     */
    @:keep
    public function toString():String {
        return '[' + componentType + ' style="' + style + '"]';
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
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        if (Utils.noeq(skinBg, null)) {
            skinBg.destroy();
            Utils.delete(skinBg);
        }
        if (Utils.noeq(skinBgDisable, null)) {
            skinBgDisable.destroy();
            Utils.delete(skinBgDisable);
        }
        if (Utils.noeq(skinDebug, null)) {
            skinDebug.destroy();
            Utils.delete(skinDebug);
        }

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
    static public var updateLayersDefault:LayersUpdater<Component> = function(component) {
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
    static public var updateSizeDefault:SizeUpdater<Component> = function(component) {
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