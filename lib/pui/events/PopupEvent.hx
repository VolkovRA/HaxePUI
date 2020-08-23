package pui.events;

import pixi.events.EventEmitter;
import pixi.display.DisplayObject;

/**
 * Событие менеджера всплывающих сообщений.
 */
class PopupEvent extends Event
{
    /**
     * Показано новое сообщение.
     * 
     * Свойство события `item` содержит ссылку на отображаемый объект.
     */
    static public inline var SHOW = "popupShow";

    /**
     * Сообщение скрыто.
     * 
     * Обратите внимание, что это событие посылается даже когда
     * свойство `Popup.notRemoveChildren=true`. На основе этого
     * события вы можете самостоятельно удалять отображаемые объекты.
     * 
     * Свойство события `item` содержит ссылку на отображаемый объект.
     */
    static public inline var HIDE = "popupHide";

    /**
     * Создать событие компонента.
     * @param type Тип события.
     * @param target Источник события.
     * @param item Отображаемый объект.
     */
    public function new(type:String, target:EventEmitter, item:DisplayObject = null) {
        super(type, target);
        this.item = item;
    }

    /**
     * Всплывающее сообщение.
     * 
     * Может быть `null`
     */
    public var item:DisplayObject;



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
     * @param item Отображаемый объект.
     * @return Новый объект события.
     */
    static public function get(type:String, target:EventEmitter, item:DisplayObject = null):PopupEvent {
        if (Utils.eq(poolLen, 0))
            return new PopupEvent(type, target, item);

        var e       = pool[--poolLen];
        e.type      = type;
        e.target    = target;
        e.item      = item;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:PopupEvent):Void {
        pool[poolLen++] = event;
    }

    /**
     * Пул объектов для повторного использования.
     */
    static private var pool = new Array<PopupEvent>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}