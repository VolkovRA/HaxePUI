package pui.events;

import pui.BitMask;
import pixi.interaction.EventEmitter;

/**
 * Событие компонента библиотеки PUI.
 * Это событие является общим для всех типов компонентов.
 */
class ComponentEvent extends Event
{
    /**
     * Компонент интерфейса обновился. (Перерисовался)
     * Свойство `changes` содержит маску выполненных изменений.
     */
    static public inline var UPDATED = "componentUpdated";

    /**
     * Создать событие компонента.
     * @param type Тип события.
     * @param target Источник события.
     */
    public function new(type:String, target:EventEmitter) {
        super(type, target);
    }

    /**
     * Маска изменений.
     * 
     * Может быть `null`
     */
    public var changes:BitMask;



    //////////////////////
    //   ПУЛ ОБЪЕКТОВ   //
    //////////////////////

    /**
     * Получить объект события.
     * 
     * Рекомендуется использовать этот метод для создания новых объектов, так как он использует пул.
     * После отработки объекта сохраните его обратно в пул вызовом статического метода: `store()`.
     * @param type Тип события.
     * @param target Источник события.
     * @return Новый объект события.
     */
    static public function get(type:String, target:EventEmitter):ComponentEvent {
        if (Utils.eq(poolLen, 0))
            return new ComponentEvent(type, target);

        var e = pool[--poolLen];
        e.type = type;
        e.target = target;
        e.changes = null;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:ComponentEvent):Void {
        pool[poolLen++] = event;
    }

    /**
     * Пул объектов для повторного использования.
     */
    static private var pool = new Array<ComponentEvent>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}