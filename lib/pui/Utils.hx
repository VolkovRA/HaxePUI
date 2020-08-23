package pui;

import haxe.extern.EitherType;
import js.Syntax;
import js.lib.Object;
import pixi.display.Container;
import pixi.display.DisplayObject;
import pixi.display.Graphics;

/**
 * Вспомогательные утилиты.
 */
@:dce
class Utils
{
    /**
     * Показать ребёнка в родителе.
     * 
     * Сокращённая форма записи добавления ребёнка в родителя.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param parent Родитель. Не должен быть `null`.
     * @param child Ребёнок. Может быть `null`.
     */
    static public inline function show(parent:Container, child:DisplayObject):Void {
        Syntax.code('if({1} != null) {0}.addChild({1});', parent, child);
    }

    /**
     * Убрать ребёнка из родителя.
     * 
     * Сокращённая форма записи удаления ребёнка из родителя.
     * Используется библиотекой компонентов повсеместно.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param parent Родитель. Не должен быть `null`.
     * @param child Ребёнок. Может быть `null`.
     */
    static public inline function hide(parent:Container, child:DisplayObject):Void {
        Syntax.code('if({1} !== null && {1}.parent === {0}) {0}.removeChild({1});', parent, child);
    }

    /**
     * Уничтожить скин компонента.
     * - Вызывает метод уничтожения скина, если он не `null`.
     * - Удаляет из компонента указанный скин.
     * @param skin Удаляемый скин.
     * @param options Опций вызова метода: `DisplayObject.destroy()`. 
     */
    static public inline function destroySkin(skin:Container, ?options:EitherType<Bool,ContainerDestroyOptions>):Void {
        Syntax.code('if ({0} != null){ {0}.destroy({1}); {0} = null; }', skin, options);
    }

    /**
     * Строговое равенство. (`===`).
     * 
     * Возможность использовать в Haxe чуть более быстрое сравнение JavaScript без авто-приведения типов.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param v1 Значение 1.
     * @param v2 Значение 2.
     * @return Результат сравнения.
     */
    static public inline function eq(v1:Dynamic, v2:Dynamic):Bool {
        return Syntax.code('({0} === {1})', v1, v2);
    }

    /**
     * Строговое неравенство. (`!==`).
     * 
     * Возможность использовать в Haxe чуть более быстрое сравнение JavaScript без авто-приведения типов.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param v1 Значение 1.
     * @param v2 Значение 2.
     * @return Результат сравнения.
     */
    static public inline function noeq(v1:Dynamic, v2:Dynamic):Bool {
        return Syntax.code('({0} !== {1})', v1, v2);
    }

    /**
     * Получить значение без вызова геттера Haxe.
     * 
     * Позволяет получить значение свойства без вызова геттера Haxe.
     * Геттер JavaScript может по прежнему вызываться.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param prop Свойство. Пример: `this.value`.
     * @param value Значение. Пример: `true`, `1` или `Привет!`.
     */
    static public inline function get(prop:Dynamic):Dynamic {
        return Syntax.code("{0}", prop);
    }

    /**
     * Записать значение без вызова сеттера Haxe.
     * 
     * Позволяет записать значение в указанное свойство без вызова сеттера Haxe.
     * Сеттер JavaScript может по прежнему вызываться.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param prop Свойство. Пример: `this.value`.
     * @param value Значение. Пример: `true`, `1` или `Привет!`.
     */
    static public inline function set(prop:Dynamic, value:Dynamic):Void {
        Syntax.code("{0} = {1};", prop, value);
    }

    /**
     * Установка размеров отображаемого объекта.
     * 
     * Сокращённая форма записи установки размеров объекта.
     * Используется библиотекой компонентов повсеместно.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param obj Отображаемый объект. (Может быть `null`)
     * @param width Новая ширина. (px)
     * @param height Новая высота. (px)
     */
    static public inline function size(obj:Container, width:Float, height:Float):Void {
        Syntax.code("if ({0} !== null) { {0}.width = {1}, {0}.height = {2} };", obj, width, height);
    }

    /**
     * Переопределить геттер отдельного объекта.
     * @param obj Объект.
     * @param property Имя свойства.
     * @param func Новый геттер.
     */
    public static inline function setGet(obj:Dynamic, property:String, func:Void->Any):Void {
        Object.defineProperty(obj, property, { get: func });
    }

    /**
     * Переопределить сеттер отдельного объекта.
     * @param obj Объект.
     * @param property Имя свойства.
     * @param func Новый сеттер.
     */
    public static inline function setSet(obj:Dynamic, property:String, func:Any->Void):Void {
        Object.defineProperty(obj, property, { set: func });
    }

    /**
     * Удалить свойство.
     * Генерирует JS код: `delete obj.property`.
     * @param property Удаляемое свойство.
     */
    public static inline function delete(property:Dynamic):Void {
        Syntax.code("delete {0}", property);
    }

    /**
     * Получить значение свойства с проверкой на `null`.
     * 
     * Возвращает значение `def`, если свойство `prop` равно `null`, `undefined` или вовсе не определено.
     * 
     * Пример:
     * ```
     * var opt = { x:12, s:"Hello!" };
     * trace(Utils.nvl(opt.x, 0)); // 12
     * trace(Utils.nvl(opt.s, "")); // "Hello!"
     * trace(Utils.nvl(opt.y, 0)); // 0
     * ```
     * @param prop Свойство.
     * @param def Значение по умолчанию.
     * @return Значение свойства.
     */
    public static inline function nvl<T>(prop:T, def:T):T {
        return Syntax.code('({0} == null ? {1} : {0})', prop, def);
    }

    /**
     * Установить значение по умолчанию.
     * 
     * Записывает значение `v` в сойство `prop`, только если оно не определено. (Равно `null` или `undefined`)
     * 
     * @param prop Свойство для записи значения.
     * @param v Значение по умолчанию.
     */
    public static inline function def<T>(prop:T, v:T):Void {
        Syntax.code('if ({0} == null) {0} = {1};', prop, v);
    }

    /**
     * Получить время, прошедшее с момента запуска приложения. (mc)
     * @see https://developer.mozilla.org/en-US/docs/Web/API/Performance/now
     */
    public static inline function uptime():Float {
        return Syntax.code('performance.now()');
    }

    /**
     * Проверить наличие флагов в битовой маске.
     * - Возвращает `true`, если маска содержит все указанные флаги.
     * - Возвращает `false`, если маска не содержит хотя бы один из флагов.
     * - Возвращает `true`, если флаги не переданы. (`flags=0`)
     * 
     * Пример:
     * ```
     * var mask = 11; // 1011
     * var flag1 = 1; // 0001
     * var flag2 = 8; // 1000
     * var flag3 = 4; // 0100
     * trace(hasFlags(flag1));          // true
     * trace(hasFlags(flag2));          // true
     * trace(hasFlags(flag1 | flag2));  // true
     * trace(hasFlags(flag3));          // false
     * trace(hasFlags(flag3 | flag1));  // false
     * ```
     * @param mask Битовая маска.
     * @param flags Флаги.
     * @return Возвращает результат сравнения маски и флагов.
     */
    public static inline function flagsAND(mask:BitMask, flags:BitMask):Bool {
        return Syntax.code('(({0} & {1}) === {1})', mask, flags);
    }

    /**
     * Проверить наличие хотя бы одного флага в битовой маске.
     * - Возвращает `true`, если маска содержит хотя бы один из переданных флагов.
     * - Возвращает `false`, если маска не содержит ни одного флага.
     * - Возвращает `false`, если флаги не переданы. (`flags=0`)
     * 
     * Пример:
     * ```
     * var mask = 11; // 1011
     * var flag1 = 1; // 0001
     * var flag2 = 8; // 1000
     * var flag3 = 4; // 0100
     * trace(hasFlags(flag1));          // true
     * trace(hasFlags(flag2));          // true
     * trace(hasFlags(flag1 | flag2));  // true
     * trace(hasFlags(flag3));          // false
     * trace(hasFlags(flag3 | flag1));  // true
     * ```
     * @param mask Битовая маска.
     * @param flags Флаги.
     * @return Возвращает результат сравнения маски и флагов.
     */
    public static inline function flagsOR(mask:BitMask, flags:BitMask):Bool {
        return Syntax.code('(({0} & {1}) > 0)', mask, flags);
    }

    /**
     * Проверить идентичность маски указанным флагам.
     * Возвращает `true`, если маска полностью совпадает с переданным флагами.
     * @param mask Битовая маска.
     * @param flags Флаги.
     * @return Возвращает результат сравнения маски и флагов.
     */
    public static inline function flagsIS(mask:BitMask, flags:BitMask):Bool {
        return Syntax.code('({0} === {1})', mask, flags);
    }

    /**
     * Перевести радианы в градусы.
     * @param rad Радианы.
     * @return Градусы.
     */
    public static inline function radToDeg(rad:Float):Float {
        return rad * 57.29577951308232; // rad * (180 / Math.PI);
    }

    /**
     * Перевести градусы в радианы.
     * @param deg Градусы.
     * @return Радианы.
     */
    public static inline function degToRad(deg:Float):Float {
        return deg * 0.017453292519943295; // deg * (Math.PI / 180);
    }

    /**
     * Получить знак числа.
     * - Возвращает `1`, если число больше нуля.
     * - Возвращает `-1`, если число меньше нуля.
     * - Возвращает `0` во всех остальных случаях.
     * @param value Число.
     * @return Знак числа.
     */
    public static function sign(value:Float):Int {
        if (value > 0)
            return 1;
        if (value < 0)
            return -1;
        
        return 0;
    }

    /**
     * Получить глубину вложенности ребёнка в корне.
     * - Возвращает **глубину вложенности**, если ребёнок содержится в корне или одном из его потомков.
     * - Возвращает `0`, если ребёнок является корнем.
     * - Возвращает `-1`, если ребёнок или корень равны `null`.
     * - Возвращает `-1`, если любой из узлов имеет `visible=false`. (Только при переданном флаге `visible`)
     * @param child Ребёнок.
     * @param root Корень.
     * @param visible Учитывать отображение. Если `true` - будет проверяться и возможность отображения ребёнка.
     * @param depth Начальный уровень вложенности.
     * @return Возвращает глубину вложенности указанного экранного объекта.
     */
    public static function getDepth(child:DisplayObject, root:Container, visible:Bool = false, depth:Int = 0):Int {
        if (child == null || root == null)
            return -1;
        
        while (depth < 1000) {
            if (visible && !child.visible)
                return -1;
            if (Utils.eq(child, root))
                return depth;
            if (child.parent == null)
                return -1;

            child = child.parent;
            depth ++;
        }

        return 1000;
    }

    /**
     * Создать обычный JavaScript массив заданной длины.
     * 
     * По сути, является аналогом для использования конструктора: `new Vector(length)`.
     * Полезен для разового выделения памяти нужной длины.
     * 
     * @param length Длина массива.
     * @return Массив.
     */
    public static inline function createArray(length:Int):Dynamic {
        return Syntax.code('new Array({0})', length);
    }

    /**
     * Проверить значение на строковой тип данных.
     * Возвращает `true`, если переданное значение является строкой.
     * @param value Проверяемое значение.
     * @return Результат проверки.
     */
    public static inline function isString(value:Dynamic):Bool {
        return Syntax.code('(typeof {0} === "string")', value);
    }

    /**
     * Проверить значение на числовой тип данных.
     * Возвращает `true`, если переданное значение является числом, `NaN` или `Infinity`.
     * @param value Проверяемое значение.
     * @return Результат проверки.
     */
    public static inline function isNumber(value:Dynamic):Bool {
        return Syntax.code('(typeof {0} === "number")', value);
    }

    /**
     * Проверить значение на булевый тип данных.
     * Возвращает `true`, если переданное значение является булевым типом данных.
     * @param value Проверяемое значение.
     * @return Результат проверки.
     */
    public static inline function isBool(value:Dynamic):Bool {
        return Syntax.code('(typeof {0} === "boolean")', value);
    }

    /**
     * Нарисовать рамку.
     * @param holst Цель вывода.
     * @param x Позиция вывода по X.
     * @param y Позиция вывода по Y.
     * @param width Ширина рамки.
     * @param height Высота рамки.
     */
    static public function dwarBorder(holst:Graphics, x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0):Void {
        if (width > 0) {
            var i = height;
            while (i-- > 0) {
                if (i % 2 == 0) {
                    holst.drawRect(x, y + i, 1, 1); // border left
                    holst.drawRect(x + width - 1, y + i, 1, 1); // border right
                }
            }
        }
        else {
            var i = height;
            while (i-- > 0) {
                if (i % 2 == 0) {
                    holst.drawRect(x, y + i, 1, 1); // border left
                }
            }
        }

        if (height > 0) {
            var i = width;
            while (i-- > 0) {
                if (i % 2 == 0) {
                    holst.drawRect(x + i, y, 1, 1); // border left
                    holst.drawRect(x + i, y + height - 1, 1, 1); // border right
                }
            }
        }
        else {
            var i = width;
            while (i-- > 0) {
                if (i % 2 == 0) {
                    holst.drawRect(x + i, y, 1, 1); // border left
                }
            }
        }
    }

    /**
     * Написать текст.
     * Поддерживается очень малый диапазон символов ASCII.
     * @param holst Цель вывода.
     * @param str Текст.
     * @param x Позиция вывода по X.
     * @param y Позиция вывода по Y.
     */
    static public function drawText(holst:Graphics, str:String, x:Float = 0, y:Float = 0):Void {
        var cw = 3; // Ширина символа
        var ch = 5; // Высота символа
        var s = 1;  // Расстояние между символами

        var i = str.length;
        while (i-- > 0) {
            var dx = x + (cw + s) * i;
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
                    holst.drawRect(dx, y, cw, ch);
            }
        }
    }
}