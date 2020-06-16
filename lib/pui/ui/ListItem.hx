package pui.ui;

import pui.events.Event;
import haxe.extern.EitherType;
import pixi.core.display.DisplayObject;

/**
 * Элемент списка.
 * 
 * Этот класс предполагается использовать как абстрактный, базовый
 * класс для отображения конкретных типов данных. Вы можете использовать
 * уже имеющиеся или создать собственный.
 * 
 * @event Event.CHANGE              Значение в поле `data` изменилось.
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
 */
class ListItem extends Component
{
    /**
     * Тип компонента `ListItem`.
     */
    static public inline var TYPE:String = "ListItem";

    /**
     * Создать элемент списка.
     */
    public function new() {
        super();
        this.componentType = TYPE;
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Отображаемые данные.
     * Это значение задаётся родительским списком автоматически.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления отображения.
     * - `Component.UPDATE_SIZE` - Для обновления позицианирования.
     * 
     * По умолчанию: `null`
     * 
     * @event Event.CHANGE Значение в поле `data` изменено.
     */
    public var data(default, set):Dynamic = null;
    function set_data(value:Dynamic):Dynamic {
        if (Utils.eq(value, data))
            return value;
        
        data = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        Event.fire(Event.CHANGE, this);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

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
        Utils.delete(data);
        super.destroy(options);
    }
}