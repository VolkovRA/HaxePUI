package pui;

/**
 * Вертикальное выравнивание. (Ось Y)
 */
@:enum abstract AlignY(String) to String
{
    /**
     * Выравнивание по верхнему краю.
     */
    var TOP = "top";

    /**
     * Выравнивание по центру.
     */
    var CENTER = "center";

    /**
     * Выравнивание по нижнему краю.
     */
    var BOTTOM = "bottom";
}