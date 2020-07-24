package pui.window;

import haxe.extern.EitherType;
import pui.ui.Component;
import pui.events.Event;
import pixi.core.display.DisplayObject;

/**
 * Окно.
 * 
 * Каждое окно это составной компонент, собирающийся из 3 отдельных частей:
 *   1. `head` Шапка, содержит заголовок и/или кнопки управления.
 *   2. `body` Тело, содержит контент.
 *   3. `footer` Подвал, используется для размещения дополнительных элементов.
 * 
 * Окно может содержать все эти элементи или ни одного. При создании окна
 * вы у себя в теме кастомизируете его под конкретный тип. Такое разделение
 * используется для гибкой кастомизации окон под любую задачу.
 * 
 * @event Event.CLOSE               Окно было закрыто. Посылается при вызове метода: `close()`.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class Window extends Component
{
    /**
     * Тип компонента `Window`.
     */
    static public inline var TYPE:String = "Window";

    /**
     * Создать окно.
     */
    public function new() {
        super();

        this.componentType = TYPE;

        Utils.set(this.updateLayers, Window.defaultLayers);
        Utils.set(this.updateSize, Window.defaultPositions);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    override function set_enabled(value:Bool):Bool {
        if (Utils.noeq(head, null)) head.enabled = value;
        if (Utils.noeq(body, null)) body.enabled = value;
        if (Utils.noeq(footer, null)) footer.enabled = value;

        return super.set_enabled(value);
    }

    /**
     * Окно закрыто.
     * 
     * Устанавливается в `true` при вызове метода `close()`.
     * 
     * По умолчанию: `false`
     */
    public var isClosed:Bool = false;

    /**
     * Заголовок.
     * 
     * Вы можете назначить заголовок для этого окна. Заголовком может быть
     * любой компонент (Например `Label`) или более специализированный объект
     * из пакета: `pui.window.controls`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления списка отображения.
     * - `Component.UPDATE_SIZE` - Для позицианирования.
     * 
     * По умолчанию: `null` (Без заголовка)
     */
    public var head(default, set):Component = null;
    function set_head(value:Component):Component {
        if (value == head)
            return value;
        if (head != null && head.parent == this)
            removeChild(head);
        if (value != null)
            value.enabled = enabled;
        head = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Тело.
     * 
     * Вы можете назначить тело для этого окна. Телом может быть любой
     * компонент (Например `Label`) или более специализированный объект из
     * пакета: `pui.window.controls`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления списка отображения.
     * - `Component.UPDATE_SIZE` - Для позицианирования.
     * 
     * По умолчанию: `null` (Без тела)
     */
    public var body(default, set):Component = null;
    function set_body(value:Component):Component {
        if (value == body)
            return value;
        if (body != null && body.parent == this)
            removeChild(body);
        if (value != null)
            value.enabled = enabled;
        body = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Подвал.
     * 
     * Вы можете назначить подвал для этого окна. Подвалом может быть любой
     * компонент (Например `Button`) или более специализированный объект из
     * пакета: `pui.window.controls`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления списка отображения.
     * - `Component.UPDATE_SIZE` - Для позицианирования.
     * 
     * По умолчанию: `null` (Без подвала)
     */
    public var footer(default, set):Component = null;
    function set_footer(value:Component):Component {
        if (value == footer)
            return value;
        if (footer != null && footer.parent == this)
            removeChild(footer);
        if (value != null)
            value.enabled = enabled;
        footer = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Закрыть окно.
     * - Вызов игнорируется, если окно уже было закрыто: `isClosed=true`.
     * 
     * Устанавливает значение свойства `isClosed=true` и посылает
     * событие: `Event.CLOSE`.
     * 
     * Больше этот метод ничего не делает! 
     */
    @:keep // <-- Может вызываться через рефлексию
    public function close():Void {
        if (isClosed)
            return;
        isClosed = true;
        Event.fire(Event.CLOSE, this);
    }

    /**
     * Выгрузить окно.
     */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        Utils.destroySkin(head, options);
        Utils.destroySkin(body, options);
        Utils.destroySkin(footer, options);

        super.destroy(options);
    }



    //////////////
    //   СЛОИ   //
    //////////////

    /**
     * Обычное положение слоёв окна.
     */
    static public var defaultLayers:LayersUpdater<Window> = function(window) {
        if (window.enabled) {
            Utils.show(window, window.skinBg);
            Utils.hide(window, window.skinBgDisable);

            Utils.show(window, window.head);
            Utils.show(window, window.footer);
            Utils.show(window, window.body);
        }
        else {
            if (Utils.eq(window.skinBgDisable, null)) {
                Utils.show(window, window.skinBg);
                //Utils.hide(window, window.skinBgDisable);
            }
            else {
                Utils.hide(window, window.skinBg);
                Utils.show(window, window.skinBgDisable);
            }

            Utils.show(window, window.head);
            Utils.show(window, window.footer);
            Utils.show(window, window.body);
        }
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Обычное позицианирование элементов окна.
     * - Шапка и подвал имеют свои изначальные значения.
     * - Содержимое растягивается на оставшееся пространство.
     * 
     * ```
     * +--------------------+
     * | Title              |
     * | Body               |
     * | Footer             |
     * +--------------------+
     * ```
     */
    static public var defaultPositions:SizeUpdater<Window> = function(window) {
        Utils.size(window.skinBg, window.w, window.h);
        Utils.size(window.skinBgDisable, window.w, window.h);
        
        var by:Float = 0;
        var wh = window.h;
        if (window.head != null) {
            window.head.update(true);
            window.head.w = window.w;
            wh -= window.head.h;
            by = window.head.h;
        }
        if (window.footer != null) {
            window.footer.update(true);
            window.footer.w = window.w;
            window.footer.y = Math.round(window.h - window.footer.h);
            wh -= window.footer.h;
        }
        if (window.body != null) {
            window.body.w = window.w;
            window.body.h = Math.max(0, Math.round(wh));
            window.body.y = Math.round(by);
            window.body.update(true);
        }
    }
}