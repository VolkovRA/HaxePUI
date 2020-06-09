package pui.dom;

/**
 * Тип устройства ввода.
 * Содержит перечисление всех доступных типов DOM.
 * @see https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/pointerType
 */
@:enum abstract PointerType(String) to String
{
    /**
     * Событие было сгенерировано устройством мыши.
     */
    var MOUSE = "mouse";

    /**
     * Событие было сгенерировано ручкой или стилусом.
     */
    var PEN = "pen";

    /**
     * Событие было создано прикосновением, например, пальцем.
     */
    var TOUCH = "touch";
}