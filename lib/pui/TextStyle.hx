package pui;

/**
 * Стили текста.
 * 
 * Этот класс используется только для исправления проблемы с некорректным
 * подсчётом размеров текста, см.: `TextMetrics`. В стальном он аналогичен
 * базовому.
 * 
 * Класс добавляет два новых свойства:
 * - `measureWidth` - Дополнительный размер занимаемой области текстом по ширине. (px)
 * - `measureHeight` - Дополнительный размер занимаемой области текстом по высоте. (px)
 * Спомощью этих свойств вы можете более точно указать занимаемую текстом область.
 * Это используется в `Label` при расчёте авторазмеров. 
 */
class TextStyle extends pixi.core.text.TextStyle
{
    /**
     * Дополнительный размер занимаемой области текстом по ширине. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    public var measureWidth:Float;

    /**
     * Дополнительный размер занимаемой области текстом по высоте. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    public var measureHeight:Float;

    /**
     * Создать новый стиль.
     * @param style Параметры по умолчанию.
     */
    public function new(?style:DefaultStyle) {
        super(style);
    }

    /**
     * Resets all properties to the defaults specified in TextStyle.prototype._default
     */
    override function reset() {
        super.reset();
        measureWidth = 0;
        measureHeight = 0;
    }

    /**
     * Creates a new TextStyle object with the same values as this one.
     * Note that the only the properties of the object are cloned.
     *
     * @return {PIXI.TextStyle} New cloned TextStyle object
     */
    override function clone():pixi.core.text.TextStyle {
        var copy = super.clone();
        untyped copy.measureWidth = measureWidth;
        untyped copy.measureHeight = measureHeight;
        return copy;
    }
}

/**
 * Параметры стилей.
 */
typedef DefaultStyle =
{
    >pixi.core.text.DefaultStyle,

    /**
     * Дополнительный размер занимаемой области текстом по ширине. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    @:optional var measureWidth:Float;

    /**
     * Дополнительный размер занимаемой области текстом по высоте. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    @:optional var measureHeight:Float;
}