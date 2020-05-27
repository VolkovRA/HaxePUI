package pui;

import js.Syntax;
import js.lib.Object;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;

/**
 * Вспомогательные утилиты.
 */
class Utils
{
    /**
     * Показать ребёнка в родителе.
     * 
     * Сокращённая форма записи добавления ребёнка в родителя.
     * Используется библиотекой компонентов повсеместно.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param parent Родитель. Не должен быть `null`.
     * @param child Ребёнок. Может быть `null`.
     */
    static public inline function show(parent:Container, child:DisplayObject):Void {
        Syntax.code('if({1} !== null) {0}.addChild({1});', parent, child);
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
        return Syntax.code('{0} === {1}', v1, v2);
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
        return Syntax.code('{0} !== {1}', v1, v2);
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
        Syntax.code("delete {0};", property);
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
        return Syntax.code('{0} == null ? {1} : {0}', prop, def);
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
     * Получить время, прошедшее с момента запуска скрипта. (mc)
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
}