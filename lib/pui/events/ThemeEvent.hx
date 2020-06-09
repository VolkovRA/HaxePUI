package pui.events;

import pixi.interaction.EventEmitter;

/**
 * Событие темы оформления.
 */
class ThemeEvent extends Event
{
    /**
     * Цикл обновления копонентов начинается.
     */
    static public inline var UPDATE_START = "themeUpdateStart";

    /**
     * Цикл обновления копонентов завершён.
     */
    static public inline var UPDATE_FINISH = "themeUpdateFinish";

    /**
     * Создать событие темы формления.
     * @param type Тип события.
     * @param target Источник события.
     */
    public function new(type:String, target:EventEmitter) {
        super(type, target);
    }

    /**
     * Количество обновлённых компонентов в последнем цикле рендера.
     * 
     * Содержит число вызовов метода: `Component.onComponentUpdate` этой темой в рамках последнего цикла рендера.
     * Это значение не учитывает ручное обновление компонентов: `Component.update(true)`.
     * Может быть полезно для отслеживания количества перерисованных компонентов за один кадр.
     * 
     * *Используется для событий:*
     * - `ThemeEvent.UPDATE_FINISH`
     * 
     * Может быть `null`
     */
    public var updates:Int;



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
    static public function get(type:String, target:EventEmitter):ThemeEvent {
        if (Utils.eq(poolLen, 0))
            return new ThemeEvent(type, target);

        var e = pool[--poolLen];
        e.type = type;
        e.target = target;
        e.updates = null;

        return e;
    }

    /**
     * Утилизировать отработанный объект в пул для повторного использования в будущем.
     * @param event Объект события.
     */
    static public function store(event:ThemeEvent):Void {
        pool[poolLen++] = event;
    }

    /**
     * Пул объектов для повторного использования.
     */
    static private var pool = new Array<ThemeEvent>();

    /**
     * Количество объектов в пуле.
     */
    static private var poolLen:Int = 0;
}