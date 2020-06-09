package pui.dom;

/**
 * Мышь.
 * Статический класс с описанием значений DOM.
 * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button
 */
class Mouse
{
    /**
     * Основная кнопка.
     * Обычно левая кнопка или неинициализированное состояние.
     */
    static public inline var MAIN:MouseKey = 0;

    /**
     * Вспомогательная кнопка.
     * Обычно колёсико или средняя кнопка мыши.
     */
    static public inline var WHEEL:MouseKey = 1;

    /**
     * Дополнительная кнопка.
     * Обычно правая кнопка мыши.
     */
    static public inline var RIGHT:MouseKey = 2;

    /**
     * Четвёртая кнопка.
     * Обычно кнопка *Назад* в браузере.
     */
    static public inline var BACK:MouseKey = 3;

    /**
     * Пятая кнопка.
     * Обычно кнопка *Вперёд* в браузере.
     */
    static public inline var NEXT:MouseKey = 4;
}

/**
 * Код клавиши мыши.
 * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button
 */
typedef MouseKey = Int;