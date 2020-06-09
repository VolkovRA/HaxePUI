package pui.ui;

import haxe.extern.EitherType;
import pui.ui.Component;
import pixi.core.display.DisplayObject;

/**
 * Элемент списка.
 * Используется как базовый, расширяемый класс для всех элементов списков.
 * 
 * Обратите внимание, что один элемент списка может использоваться для отображения
 * **разных данных одного типа**. Это нужно для того, чтобы не создавать по одному
 * отображающему элементу на все данные в списке, которые не помещаются разом.
 * 
 * Каждый конкретный список имеет пул элементов отображения, создаёт новые в случае
 * необходимости.
 */
class AListItem<DATA:Dynamic> extends Component
{
    /**
     * Тип компонента `AListItem`.
     */
    static public inline var TYPE:String = "AListItem";

    /**
     * Создать список элементов.
     * @param params Параметры.
     */
    public function new(params:Dynamic = null) {
        super(TYPE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Отображаемые данные.
     * 
     * Это значение задаётся/удаляется родительским списком автоматически,
     * вы не должны управлять им самостоятельно. Вы можете переопределить
     * сеттер для добавления необходимой логики отображения данных.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для перерисовки слоёв.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null` (Данные не заданы)
     */
    public var data(default, set):DATA = null;
    function set_data(value:DATA):DATA {
        data = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Индекс элемента в списке.
     * 
     * Это значение задаётся родительским списком автоматически и может быть полезно
     * для определения позиции элемента. Это значение имеет информативный характер,
     * его изменение ни к чему не приведёт.
     * 
     * По умолчанию: `-1` (Не содержится в списке)
     */
    public var index(default, set):Int = -1;
    function set_index(value:Int):Int {
        index = value;
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Выгрузить элемент списка.
	 */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        Utils.delete(data);
    }
}