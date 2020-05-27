package pui;

import pixi.core.graphics.Graphics;

/**
 * Пиксельный шрифт.
 * 
 * Класс используется для вывода текста напрямую в Graphics, без использования
 * внешнего шрифта. Используется в целях отладки для вывода сообщений прямо в графику.
 * 
 * Поддерживается очень малый диапазон символов ASCII.
 */
class PixelsString
{
    static private inline var CHAR_WIDTH = 3;
    static private inline var CHAR_HEIGHT = 5;
    static private inline var SPACE = 1;

    /**
     * Распечатать текст.
     * @param holst Цель вывода.
     * @param str Текст.
     * @param x Позиция вывода по X.
     * @param y Позиция вывода по Y.
     */
    static public function draw(holst:Graphics, str:String, x:Float = 0, y:Float = 0):Void {
        var i = str.length;
        while (i-- > 0) {
            var dx = x + (CHAR_WIDTH + SPACE) * i;
            switch (str.charAt(i)) {
                case "0":
                    holst.drawRect(dx+1, y, 1, 1);
                    holst.drawRect(dx+1, y+4, 1, 1);
                    holst.drawRect(dx, y, 1, 5);
                    holst.drawRect(dx+2, y, 1, 5);
                case "1":
                    holst.drawRect(dx+1, y, 1, 5);
                case "2":
                    holst.drawRect(dx, y, 2, 1);
                    holst.drawRect(dx+1, y+2, 1, 1);
                    holst.drawRect(dx+1, y+4, 2, 1);
                    holst.drawRect(dx+2, y, 1, 3);
                    holst.drawRect(dx, y+2, 1, 3);
                case "3":
                    holst.drawRect(dx, y, 2, 1);
                    holst.drawRect(dx, y+2, 2, 1);
                    holst.drawRect(dx, y+4, 2, 1);
                    holst.drawRect(dx+2, y, 1, 5);
                case "4":
                    holst.drawRect(dx, y, 1, 3);
                    holst.drawRect(dx+2, y, 1, 5);
                    holst.drawRect(dx+1, y+2, 1, 1);
                case "5":
                    holst.drawRect(dx, y, 3, 1);
                    holst.drawRect(dx, y+2, 3, 1);
                    holst.drawRect(dx, y+4, 3, 1);
                    holst.drawRect(dx, y+1, 1, 1);
                    holst.drawRect(dx+2, y+3, 1, 1);
                case "6":
                    holst.drawRect(dx, y, 3, 1);
                    holst.drawRect(dx, y+2, 3, 1);
                    holst.drawRect(dx, y+4, 3, 1);
                    holst.drawRect(dx, y+1, 1, 1);
                    holst.drawRect(dx, y+3, 1, 1);
                    holst.drawRect(dx+2, y+3, 1, 1);
                case "7":
                    holst.drawRect(dx, y, 3, 1);
                    holst.drawRect(dx+2, y+1, 1, 4);
                case "8":
                    holst.drawRect(dx, y, 3, 1);
                    holst.drawRect(dx+1, y+2, 1, 1);
                    holst.drawRect(dx, y+4, 3, 1);
                    holst.drawRect(dx, y+1, 1, 3);
                    holst.drawRect(dx+2, y+1, 1, 3);
                case "9":
                    holst.drawRect(dx, y, 2, 1);
                    holst.drawRect(dx, y+2, 2, 1);
                    holst.drawRect(dx, y+1, 1, 1);
                    holst.drawRect(dx+2, y, 1, 5);
                case "x":
                    holst.drawRect(dx, y+1, 1, 1);
                    holst.drawRect(dx+1, y+2, 1, 1);
                    holst.drawRect(dx+2, y+3, 1, 1);
                    holst.drawRect(dx+2, y+1, 1, 1);
                    holst.drawRect(dx, y+3, 1, 1);
                case ".":
                    holst.drawRect(dx+1, y+4, 1, 1);
                case ",":
                    holst.drawRect(dx+1, y+4, 1, 1);
                case "-":
                    holst.drawRect(dx, y+2, 3, 1);
                case " ":
                    continue;
                default:
                    holst.drawRect(dx, y, CHAR_WIDTH, CHAR_HEIGHT);
            }
        }
    }
}