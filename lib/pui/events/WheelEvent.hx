package pui.events;

import pixi.interaction.EventEmitter;

/**
 * Событие промотки колёсиком мыши.
 */
class WheelEvent extends Event
{
    /**
     * Промотка колесом мыши.
     */
    static public inline var WHEEL = "wheel";

    /**
     * Создать событие колёсика мыши.
     * @param type Тип события.
     * @param target Источник события.
     */
    public function new(type:String, target:EventEmitter) {
        super(type, target);
    }

    /**
     * Нативный объект события DOM.
     * Не может быть `null`
     */
    public var native:js.html.WheelEvent;

    /**
     * Всплытие события вверх по иерархии дисплей объектов.
     * 
     * Необходимо для предотвращения диспетчеризации события выше стоящим компонентам
     * интерфейса. Изначально это свойство равно `true`, то есть, событие будет передано
     * всем объектам, находящихся под курсором. Если во время обработки события это
     * значение установить в `false`, событие не будет послано компонентам в выше
     * стоящих узлах от *текущего*.
     * 
     * Это свойство не влияет на нативное событие, в частности, на предотвращение
     * дефолтного поведения браузера. (Промотка страницы)
     * 
     * По умолчанию: `true` (Всплывать)
     */
    public var bubbling:Bool = true;



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
    static public function get(type:String, target:EventEmitter):WheelEvent {
        if (Utils.eq(poolLen, 0))
            return new WheelEvent(type, target);

        var e = pool[--poolLen];
        e.type = type;
        e.target = target;
        e.bubbling = true;
        e.native = null;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:WheelEvent):Void {
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
    static private var pool = new Array<WheelEvent>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}