package pui;

/**
 * Ориентация.
 */
@:enum abstract Orientation(String) to String
{
    /**
     * Горизонтальная.
     */
    var HORIZONTAL = "horizontal";

    /**
     * Вертикальная.
     */
    var VERTICAL = "vertical";
}