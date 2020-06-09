package pui.ui;

import pui.ui.Component;
import pixi.core.display.Container;

/**
 * Листинг элементов.
 * 
 * Это абстрактный, базовый класс для всех списков. Он не предназначен для
 * непосредственного использования, вместо этого, вы должны создать собственный
 * класс - наследник.
 * 
 * Отображает проматываемый список элементов. Может содержать абсолютно любой
 * тип данных, однако, вы должны указать класс элемента, который будет
 * использоваться для их отображения. Список автоматически создаст нужное
 * количество экземпляров для отображения.
 * 
 * События:
 * - `UIEvent.UPDATE`           Компонент обновился: `AList->changes->Void`. (Передаёт старые изменения)
 * - *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class AList<DATA:Dynamic, VIEW:AListItem<DATA>> extends Component
{
    /**
     * Тип компонента `AList`.
     */
    static public inline var TYPE:String = "AList";

    // Приват
    private var items = new Array<DATA>();
    private var pool = new Array<VIEW>();
    private var content = new Container();

    /**
     * Создать список элементов.
     */
    public function new() {
        super(TYPE);

        Utils.set(this.updateLayers, AList.defaultLayers);
        Utils.set(this.updateSize, AList.defaultSize);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onItemUpdated(item:Component, changes:BitMask):Void {
        update(false, Component.UPDATE_SIZE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////
    
    /**
     * Количество элементов в списке.
     * По умолчанию: `0`
     */
    public var length(get, never):Int;
    inline function get_length():Int {
        return items.length;
    }

    /**
     * Список параметров, передаваемых в конструктор новых отображалок для элементов списка.
     * По умолчанию: `null`
     */
    public var params:Dynamic = null;

    /**
     * Ориентация списка.
     * 
     * Позволяет задать горизонтыльную или вертикальную ориентацию.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `Orientation.HORIZONTAL`
     */
    public var orientation(default, set):Orientation = Orientation.HORIZONTAL;
    function set_orientation(value:Orientation):Orientation {
        if (Utils.eq(value, orientation))
            return value;

        orientation = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }



    /**
     * Текущая скорость перемещения контента. (px/sec)
     * 
     * Это значение управляется автоматически при скроллинге списка свапом.
     * Вы можете вручную задать скорость, инициируя тем самым промотку списка
     * или резко остановить её, задав значение `0`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `0`.
     */
    public var vel(default, set):Float = 0;
    function set_vel(value:Float):Float {
        if (Utils.eq(vel, value))
            return value;

        vel = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }




    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Получить элемент списка.
     * @param index Индекс элемента в списке.
     * @return Данные в списке по указанному индексу.
     */
    inline public function at(index:Int):DATA {
        return items[index];
    }

    /**
     * Установить значение списка.
     * Устанавливает в указанный индекс заданное значение.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для обновления списка.
     * 
     * @param index Индекс элемента списка.
     * @param value Новое значение.
     */
    public function set(index:Int, value:DATA):Void {
        items[index] = value;
        update(false, Component.UPDATE_SIZE);
    }

    /**
     * Добавить элемент в список.
     * 
     * Никаких проверок не производится, если вы добавите `null` - он добавится в список.
     * Если элемент уже содержится в списке, их там будет два.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для обновления списка.
     * 
     * @param item Новый элемент списка.
     */
    public function add(item:DATA):Void {
        items.push(item);
        update(false, Component.UPDATE_SIZE);
    }

    /**
     * Удалить элемент списка, следующие за ним сдвигаются на `-1`. (Медленно)
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для обновления списка.
     * 
     * @param index Индекс удаляемого элемента.
     * @return Удалённый элемент списка.
     */
    public function remove(index:Int):DATA {
        var item = items[index];
        items = items.splice(index, 1);
        update(false, Component.UPDATE_SIZE);
        return item;
    }

    /**
     * Очистить весь список.
     * Удаляет все данные из списка.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для обновления списка.
     */
    public function clear():Void {
        items = new Array<DATA>();
        update(false, Component.UPDATE_SIZE);
    }

    /**
     * Проверить наличие элемента в списке. (Линейный поиск)
     * Возвращает `true`, если выполняется обычное равенство `==` хотя бы для одного элемента в списке.
     * @param item Искомый элемент.
     * @return Возвращает `true`, если выполняется обычное равенство `==` хотя бы для одного элемента в списке.
     */
    public function has(item:DATA):Bool {
        var i = 0;
        var len = items.length;
        while (i < len) {
            if (items[i++] == item)
                return true;
        }
        return false;
    }

    /**
     * Получить индекс первого найденного элемента в списке. (Линейный поиск)
     * Возвращает индекс первого найденного элемента `==` или `-1`, если такого элемента нет в списке.
     * @param item Искомый элемент.
     * @return Возвращает индекс первого найденного элемента `==` или `-1`, если такого элемента нет в списке.
     */
    public function getIndex(item:DATA):Int {
        var i = 0;
        var len = items.length;
        while (i < len) {
            if (items[i] == item)
                return i;
            else
                i ++;
        }
        return -1;
    }


    ///////////////////////////////
    //   БАТАРЕЙКИ В КОМПЛЕКТЕ   //
    ///////////////////////////////

    // Слои:
    /**
     * Обычное положение слоёв.
     */
    static public var defaultLayers:LayersUpdater<AList<Dynamic, AListItem<Dynamic>>> = function(list) {

    }

    // Позицианирование:
    /**
     * Обычное позицианирование.
     */
    static public var defaultSize:SizeUpdater<AList<Dynamic, AListItem<Dynamic>>> = function(list) {
        Utils.size(list.skinBg, list.w, list.h);
        Utils.size(list.skinBgDisable, list.w, list.h);

    }

    // Гашение скоростей:
    static public var dampingLinear:DampingFunction = function(v, t) {
        return 0;
    }
}

/**
 * Функция гашения.
 * 
 * Используется для постепенного приближения заданной переменной к нулю.
 * Например, для плавного замедления скорости движения.
 * 
 * Результат вычисления должен стремиться к нулю. (Меньше, чем было до вызова)
 * 
 * @param value Текущее значение изменяемой переменной.
 * @param time Прошедшее время. (sec)
 * @return Новое значение изменяемой переменной.
 */
typedef DampingFunction = Float->Float->Float;