package pui.events;

import pixi.interaction.EventEmitter;

/**
 * Событие PUI.
 * 
 * Это базовое событие, используемое библиотекой компонентов графического интерфейса PUI.
 * Используется как отдельное событие и расширяется другими, более специфическими типами событий.
 * 
 * *пс. Не путайте эти события с нативными событиями PixiJS или событиями DOM API.*
 */
class Event
{
    /**
     * Изменение состояния.
     */
    static public inline var STATE = "puiState";

    /**
     * Изменение.
     */
    static public inline var CHANGE = "puiChange";

    /**
     * Нажатие.
     */
    static public inline var PRESS = "puiPress";

    /**
     * Клик.
     * Отличается от нажатия тем, что регистрируется только после отпускания клавиши.
     */
    static public inline var CLICK = "puiClick";

    /**
     * Двойное клик.
     * Срабатывает при быстром, кратковременном, двойном нажатии.
     */
    static public inline var DOUBLE_CLICK = "puiDoubleClick";

    /**
     * Перетаскивание началось.
     */
    static public inline var START_DRAG = "puiStartDrag";

    /**
     * Перетаскивание завершено.
     */
    static public inline var STOP_DRAG = "puiStopDrag";

    /**
     * Перетаскивание.
     */
    static public inline var DRAG = "puiDrag";

    /**
     * Закрытие.
     */
    static public inline var CLOSE = "puiClose";

    /**
     * Создать событие.
     * @param type Тип события.
     * @param target Источник события.
     */
    public function new(type:String, target:EventEmitter) {
        this.type = type;
        this.target = target;
    }

    /**
     * Тип события.
     * Не может быть `null`
     */
    public var type(default, null):String;

    /**
     * Источник события.
     * Не может быть `null`
     */
    public var target(default, null):EventEmitter;



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
     static public function get(type:String, target:EventEmitter):Event {
        if (Utils.eq(poolLen, 0))
            return new Event(type, target);

        var e = pool[--poolLen];
        e.type = type;
        e.target = target;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:Event):Void {
        pool[poolLen++] = event;
    }

    /**
     * Послать событие.
     * @param type Тип события.
     * @param target Источник события.
     */
    static public function fire(type:String, target:EventEmitter):Void {
        var e = get(type, target);
        target.emit(type, e);
        pool[poolLen++] = e;
    }

    /**
     * Пул объектов для повторного использования.
     */
    static private var pool = new Array<Event>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}