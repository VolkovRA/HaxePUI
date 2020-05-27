package pui;

/**
 * Параметры настройки для двойного клика.
 */
typedef DoubleClickParams =
{
    /**
     * Двойное нажатие включено.
     * Если `true` - Объект будет регистрировать двойные нажатия.
     * 
     * По умолчанию: `true`
     */
    var enabled:Bool;

    /**
     * Максимальное время между двумя кликами. (mc)
     * 
     * По умолчанию: `250` (Четверть секунды)
     */
    var time:Int;

    /**
     * Максимальная дистанция между кликами. (px)
     * Позволяет более тонко настроить срабатывание двойного нажатия,
     * если между кликами бывает небольшой зазор из-за смещения курсора.
     * 
     * По умолчанию: `10`
     */
    var dist:Float;

    /**
     * Использовать только основное устройство ввода.
     * 
     * Основное устройство - это мышь, первое касание на сенсорном устройстве или т.п.
     * - Если `true` - Объект будет реагировать только на ввод с основного устройства.
     * - Если `false` - Объект будет реагировать на ввод с любого устройства.
     * 
     * По умолчанию: `true`
     * 
     * @see PointerEvent.isPrimary: https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/isPrimary
     */
    var isPrimary:Bool;

    /**
     * Маска клавиш реагирования.
     * 
     * Используется для контроля клавиш, которыми может осуществляться взаимодействие с объектом.
     * По умолчанию объект реагирует только на нажатие левой кнопкой мыши. Вы можете добавить
     * реагирование и на правую кнопку следующим образом:
     * ```
     * var options:DoubleTapParams = {
     *     buttons: MouseButtons.LEFT | MouseButtons.RIGHT, // Реагирует на правую и на левую кнопки мыши
     * }
     * ```
     * 
     * По умолчанию: `MouseButtons.LEFT`
     */
    var buttons:BitMask;
}