package pui.window;

import js.lib.Error;
import pui.ui.Button;
import pui.ui.Label;
import pui.ui.Component;
import pui.events.Event;
import pui.events.PopupEvent;
import pixi.core.display.DisplayObject;
import pixi.core.display.Container;

/**
 * Менеджер всплывающих окон.
 * 
 * Используется для контроля отображения всплывающих сообщений.
 * В первую очередь предназначен для отображения экземпляров
 * класса `Window`, но может отображать любой дисплей объект.
 * 
 * Менеджер представляет собою контейнер, в который по очереди
 * помещаются всплывающие сообщения (дисплей объекты). В один
 * момент времени отображается только один бъект.
 * 
 * Менеджер не использует анимацию, вместо этого он посылает
 * события, чтобы вы могли самостоятельно подключить нужные вам
 * эффекты.
 * 
 * @event PopupEvent.SHOW   Показано новое сообщение.
 * @event PopupEvent.HIDE   Сообщение скрыто.
 */
class Popup extends Container
{
    // Приват
    private var items:Array<DisplayObject> = [];
    private var map:Dynamic = {};

    /**
     * Создать новый экземпляр менеджера всплывающих сообщений.
     */
    public function new() {
        super();
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Количество объектов в очереди для отображения.
     * - Если `0`, на экране ничего не отображается и в очереди пусто.
     * - Если `1`, на экране есть один элемент, в очереди пусто.
     * 
     * По умолчанию: `0`
     */
    public var length(default, null):Int = 0;

    /**
     * Отображаемое сообщение.
     * 
     * Автоматически изменяется при выводе нового всплывающего сообщения.
     * Вы можете отслеживать это при помощи событий.
     * 
     * По умолчанию: `null`
     */
    public var current(default, null):DisplayObject = null;

    /**
     * Не удалять детей из списка отображения.
     * 
     * Это свойство может быть полезно, если вы хотите использовать
     * отложенное удаление детей из списка отображения, например, для
     * анимации плавного исчезновения. Если вы используете эту опцию,
     * вы **должны** будете самостоятельно следить за удалением всех
     * детей из менеджера, иначе они там останутся там навсегда.
     * Используйте для этого события менеджера всплывающих сообщений.
     * 
     * По умолчанию: `false` (Удалять)
     */
    public var notRemoveChildren:Bool = false;

    /**
     * Ширина области отображения. (px)
     * 
     * Это значение используется для указания размеров области вывода.
     * Все всплывающие сообщения автоматически позицианируются, исходя
     * из их собственных размеров и области отображения менеджера.
     * 
     * - Это значение не может быть меньше `0`, быть равным `null`, `NaN` или т.п.
     * - Изменение этого значения вызывает функцию позицианирования.
     * 
     * По умолчанию: `550`.
     */
    public var w(default, set):Float = 550;
    function set_w(value:Float):Float {
        if (value > 0)
            w = value;
        else
            w = 0;

        positioning(this);
        return value;
    }

    /**
     * Высота области отображения. (px)
     * 
     * Это значение используется для указания размеров области вывода.
     * Все всплывающие сообщения автоматически позицианируются, исходя
     * из их собственных размеров и области отображения менеджера.
     * 
     * - Это значение не может быть меньше `0`, быть равным `null`, `NaN` или т.п.
     * - Изменение этого значения вызывает функцию позицианирования.
     * 
     * По умолчанию: `400`.
     */
    public var h(default, set):Float = 400;
    function set_h(value:Float):Float {
        if (value > 0)
            h = value;
        else
            h = 0;

        positioning(this);
        return value;
    }

    /**
     * Функция позицианирования содержимого.
     * 
     * Так как все гуи абсолютно разные, то и список отображения может быть
     * очень индивидуальным делом, особенно в играх. Поэтому, библиотека
     * предоставляет API для назначения собственных функций управления
     * списком отображения.
     * 
     * По умолчанию: `Component.updateLayersDefault`.
     */
    public var positioning:LayersUpdater<Dynamic> = Popup.posCenter;
    function set_positioning(value:LayersUpdater<Dynamic>):LayersUpdater<Dynamic> {
        if (Utils.eq(value, positioning))
            return value;
        if (Utils.eq(value, null))
            throw new Error("Функция позицианирования не может быть null");

        positioning = value;
        value(this);
        return value;
    }

    /**
     * Имя стиля, применяемого к новым окнам: `Popup.alert()`.
     * 
     * Используется как дефолтное имя стиля, создаваемых этим методом.
     * 
     * По умолчанию: `""` (Стиль не указан!)
     */
    public var defaultWindowAlert:String = "";

    /**
     * Имя стиля, применяемого к новым окнам: `Popup.confirm()`.
     * 
     * Используется как дефолтное имя стиля, создаваемых этим методом.
     * 
     * По умолчанию: `""` (Стиль не указан!)
     */
    public var defaultWindowConfirm:String = "";



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Получить элемент списка.
     * @param index Индекс элемента в списке.
     * @return Отображаемый объект.
     */
    inline public function at(index:Int):DisplayObject {
        return items[index];
    }

    /**
     * Добавить всплывающее сообщение.
     * - Если список пустой, добавленный элемент сразу отображается на экране.
     * - Если элемент уже содержится в списке, он переносится в начало и показывается на экране.
     * - Вызов игнорируется, если передан `null`.
     * @param item Всплывающее сообщение.
     */
    public function add(item:DisplayObject):Void {
        if (item == null)
            return;

        // Уже есть в списке:
        if (untyped map[item]) {
            if (current == item)
                return;

            var len = length;
            while (len-- != 0) {
                if (items[len] == item)
                    break;
            }
            while (len-- != 0)
                items[len+1] = items[len];
            items[0] = item;

            var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
            var es = PopupEvent.get(PopupEvent.SHOW, this, item);
            current.off(Event.CLOSE, onClose);
            current = item;
            current.on(Event.CLOSE, onClose);
            if (!notRemoveChildren && eh.item.parent == this)
                removeChild(eh.item);
            addChild(es.item);
            positioning(this);
            emit(eh.type, eh);
            emit(es.type, es);
            PopupEvent.store(eh);
            PopupEvent.store(es);
            return;
        }

        // Список пустой:
        if (length == 0) {
            untyped map[item] = true;
            items[0] = item;
            length = 1;

            current = item;
            current.on(Event.CLOSE, onClose);

            var es = PopupEvent.get(PopupEvent.SHOW, this, item);
            addChild(item);
            positioning(this);
            emit(es.type, es);
            PopupEvent.store(es);
            return;
        }

        // Вставка в начало:
        untyped map[item] = true;
        var len = length++;
        while (len-- != 0)
            items[len+1] = items[len];
        items[0] = item;

        var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
        var es = PopupEvent.get(PopupEvent.SHOW, this, item);
        current.off(Event.CLOSE, onClose);
        current = item;
        current.on(Event.CLOSE, onClose);
        if (!notRemoveChildren && eh.item.parent == this)
            removeChild(eh.item);
        addChild(es.item);
        positioning(this);
        emit(eh.type, eh);
        emit(es.type, es);
        PopupEvent.store(eh);
        PopupEvent.store(es);
    }

    /**
     * Удалить всплывающее сообщение.
     * - Вызов игнорируется, если элемент не находится в списке или был передан `null`.
     * @param item Всплывающее сообщение.
     */
    public function remove(item:DisplayObject):Void {
        if (item == null || untyped map[item] == null)
            return;

        var i = 0;
        var len = length;
        while (i < len) {
            if (items[i] == item)
                break;
            i ++;
        }
        while (i < len) {
            items[i] = items[i+1];
            i ++;
        }
        items[length--] = null;
        Utils.delete(untyped map[item]);

        // Это был самый первый элемент:
        if (current == item) {
            if (length == 0) {
                // Это был единственный элемент:
                var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
                current.off(Event.CLOSE, onClose);
                current = null;
                if (!notRemoveChildren && eh.item.parent == this)
                    removeChild(eh.item);
                emit(eh.type, eh);
                PopupEvent.store(eh);
            }
            else {
                // Есть другие:
                var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
                var es = PopupEvent.get(PopupEvent.SHOW, this, items[0]);
                current.off(Event.CLOSE, onClose);
                current = items[0];
                current.on(Event.CLOSE, onClose);
                if (!notRemoveChildren && eh.item.parent == this)
                    removeChild(eh.item);
                addChild(current);
                positioning(this);
                emit(eh.type, eh);
                emit(es.type, es);
                PopupEvent.store(eh);
                PopupEvent.store(es);
            }
        }
    }

    /**
     * Наличие указанного элемента в списке.
     * Возвращает `true`, если указанный элемент находится в списке.
     * @param item Проверяемый элемент.
     * @return Возвращает `true`, если указанный элемент находится в списке.
     */
    public function has(item:DisplayObject):Bool {
        return untyped !!map[item]; 
    }

    /**
     * Очистить весь список.
     * - Удаляет все сообщения в очереди.
     * - Удаляет текущее сообщение на экране. (Если есть)
     */
    public function clear():Void {
        items = [];
        map = {};
        length = 0;

        if (current != null) {
            var e = PopupEvent.get(PopupEvent.HIDE, this, current);
            current = null;
            if (!notRemoveChildren && e.item.parent == this)
                removeChild(e.item);
            emit(e.type, e);
            PopupEvent.store(e);
        }
    }

    private function onClose(e:Event):Void {
        if (length == 1) {
            // Единственный элемент в списке:
            items[0] = null;
            length = 0;
            Utils.delete(untyped map[current]);
            current.off(Event.CLOSE, onClose);
            var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
            if (!notRemoveChildren && eh.item.parent == this)
                removeChild(eh.item);
            emit(eh.type, eh);
            PopupEvent.store(eh);
        }
        else {
            // Очередь не пустая:
            var len = length;
            var i = 0;
            while (i < len) {
                items[i] = items[i+1];
                i ++;
            }
            items[length--] = null;
            Utils.delete(untyped map[current]);

            var eh = PopupEvent.get(PopupEvent.HIDE, this, current);
            var es = PopupEvent.get(PopupEvent.SHOW, this, items[0]);
            current.off(Event.CLOSE, onClose);
            current = items[0];
            current.on(Event.CLOSE, onClose);
            if (!notRemoveChildren && eh.item.parent == this)
                removeChild(eh.item);
            addChild(current);
            positioning(this);
            emit(eh.type, eh);
            emit(es.type, es);
            PopupEvent.store(eh);
            PopupEvent.store(es);
        }
    }



    /////////////////
    //   САХАРОК   //
    /////////////////

    /**
     * Вывести окно с сообщением.
     * @param message Текст сообщения.
     * @param title Заголовок окна.
     * @param ok Текст на кнопке.
     * @return Окно с сообщением.
     */
    public function alert(message:String, title:String = "Message", ok:String = "OK"):Window {
        var w = new Window();
        w.style = defaultWindowAlert;
        w.update(true);

        // Шапка:
        var item:Dynamic = w.head;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", title);
            else if (item.labelTitle)
                Reflect.setProperty(item.labelTitle, "text", title);
        }

        // Тело:
        item = w.body;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", message);
            else if (item.labelTitle)
                Reflect.setProperty(item.labelMessage, "text", message);
        }

        // Футер:
        item = w.footer;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", ok);
            else if (item.buttonOK)
                Reflect.setProperty(item.buttonOK, "text", ok);
        }

        add(w);
        return w;
    }

    /**
     * Вывести окно с запросом подтверждения.
     * @param message Текст сообщения.
     * @param title Заголовок окна.
     * @param ok Текст на кнопке подтверждения.
     * @param cancel Текст на кнопке отмены.
     * @return Окно с сообщением.
     */
    public function confirm(message:String, title:String = "Confirm", ok:String = "OK", cancel:String = "Cancel"):Window {
        var w = new Window();
        w.style = defaultWindowConfirm;
        w.update(true);


        // Шапка:
        var item:Dynamic = w.head;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", title);
            else if (item.labelTitle)
                Reflect.setProperty(item.labelTitle, "text", title);
        }

        // Тело:
        item = w.body;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", message);
            else if (item.labelTitle)
                Reflect.setProperty(item.labelMessage, "text", message);
        }

        // Футер:
        item = w.footer;
        if (item != null) {
            if (item.text != null)
                Reflect.setProperty(item, "text", ok);
            else if (item.buttonOK)
                Reflect.setProperty(item.buttonOK, "text", ok);

            if (item.buttonCancel)
                Reflect.setProperty(item.buttonCancel, "text", cancel);
        }

        add(w);
        return w;
    }



    //////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ   //
    //////////////////////////

    /**
     * Позицианирование окна по центру. (По умолчанию)
     */
    static public var posCenter:Positioner<Popup> = function(popup) {
        if (popup.current == null)
            return;

        var width:Float = untyped popup.current.w; // for pui components
        if (width == null)
            width = untyped popup.current.width; // for others
        if (width == null)
            width = 0;

        var height:Float = untyped popup.current.h; // for pui components
        if (height == null)
            height = untyped popup.current.height; // for others
        if (height == null)
            height = 0;

        popup.current.x = Math.round((popup.w-width)/2);
        popup.current.y = Math.round((popup.h-height)/2);
    }
}

/**
 * Функция позицианирования менеджера. 
 * @see Управление позицианированием: `Component.updateLayers`
 */
typedef Positioner<T:Popup> = T->Void;