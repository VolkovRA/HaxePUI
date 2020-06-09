package pui.events;

import pixi.interaction.EventEmitter;

/**
 * Событие перетаскивания.
 */
class DragEvent extends Event
{
    /**
     * Перетаскивание началось.
     */
    static public inline var START = "dragStart";

    /**
     * Перетаскивание завершилось.
     */
    static public inline var STOP = "dragStop";

    /**
     * Выполняется перетаскивание.
     */
    static public inline var MOVE = "dragMove";

    /**
     * Выход за диапазоны разрешённой области.
     * 
     * Специализированное событие, информирующее о перетаскивании объекта за пределы разрешённой зоны.
     * Свойства `overdragX` и `overdragY` содержат избыточное расстояния. (px)
     */
    static public inline var OVERDRAG = "dragOver";

    /**
     * Создать событие перетаскивания.
     * @param type Тип события.
     * @param target Источник события.
     */
    public function new(type:String, target:EventEmitter) {
        super(type, target);
    }

    /**
     * Избыточное расстояние по оси X. (px)
     * 
     * Содержит избыточное расстояние, на которое переместился объект в ходе перетаскивания.
     * 
     * *Используется для событий:*
     * - `DragEvent.OVERDRAG`
     * 
     * Может быть `null`
     */
    public var overdragX:Float;

    /**
     * Избыточное расстояние по оси Y. (px)
     * 
     * Содержит избыточное расстояние, на которое переместился объект в ходе перетаскивания.
     * 
     * *Используется для событий:*
     * - `DragEvent.OVERDRAG`
     * 
     * Может быть `null`
     */
    public var overdragY:Float;



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
    static public function get(type:String, target:EventEmitter):DragEvent {
        if (Utils.eq(poolLen, 0))
            return new DragEvent(type, target);

        var e = pool[--poolLen];
        e.type = type;
        e.target = target;
        e.overdragX = null;
        e.overdragY = null;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:DragEvent):Void {
        pool[poolLen++] = event;
    }

    /**
     * Пул объектов для повторного использования.
     */
    static private var pool = new Array<DragEvent>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}