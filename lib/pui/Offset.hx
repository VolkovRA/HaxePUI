package pui;

/**
 * Отступы.
 * Используется для задания отступов.
 */
typedef Offset =
{
    /**
     * Верхний отступ. (px)
     */
    @:optional var top:Float;

    /**
     * Левый отступ. (px)
     */
    @:optional var left:Float;

    /**
     * Правый отступ. (px)
     */
    @:optional var right:Float;

    /**
     * Нижний отступ. (px)
     */
    @:optional var bottom:Float;
}