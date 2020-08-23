package pui.ext;

import pixi.text.TextStyle;

/**
 * Стили текста.
 * 
 * Этот класс используется только для исправления проблемы с некорректным
 * подсчётом размеров текста, см.: `TextMetrics`. В остальном он аналогичен
 * базовому.
 * 
 * Класс добавляет два новых свойства:
 * - `measureWidth` - Дополнительный размер занимаемой области текстом по ширине. (px)
 * - `measureHeight` - Дополнительный размер занимаемой области текстом по высоте. (px)
 * Спомощью этих свойств вы можете более точно указать занимаемую текстом область.
 * Это используется в `Label` при расчёте авторазмеров. 
 */
class TextStyleMeasure extends TextStyle
{
    /**
     * Дополнительный размер занимаемой области текстом по ширине. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    public var measureWidth:Null<Float>;

    /**
     * Дополнительный размер занимаемой области текстом по высоте. (px)
     * Используется для расчётов занимаемой области текстом.
     */
    public var measureHeight:Null<Float>;

    /**
     * Создать новый стиль.
     * @param style Параметры по умолчанию.
     */
    public function new(?style:TextStyleMeasureOptions) {
        super(style);
    }

    /**
     * Resets all properties to the defaults specified in TextStyle.prototype._default
     */
    override function reset() {
        super.reset();
        measureWidth = null;
        measureHeight = null;
    }

    /**
     * Creates a new TextStyle object with the same values as this one.
     * Note that the only the properties of the object are cloned.
     *
     * @return {PIXI.TextStyle} New cloned TextStyle object
     */
    override function clone():TextStyle {
        var copy = super.clone();
        untyped copy.measureWidth = measureWidth;
        untyped copy.measureHeight = measureHeight;
        return copy;
    }
}

/**
 * Параметры стилей.
 */
typedef TextStyleMeasureOptions =
{
    >TextStyleOptions,

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