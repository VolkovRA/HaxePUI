package pui.ui;

import haxe.extern.EitherType;
import js.Syntax;
import js.lib.Error;
import pixi.display.Container;
import pixi.geom.Rectangle;
import pui.events.Event;
import pui.ui.Component;

/**
 * Листинг элементов.
 * 
 * Расширяет обычный скроллер, добавляя в него дополнительную функциональность.
 * Предназначен для отображения списков, оптимизирован для большого количества элементов.
 * Ведёт себя как массив.
 * 
 * Перед использованием списка вы должны указать класс - визуализатора элементов.
 * Этот класс должен расширять `ListItem`.
 * 
 * Общий принцип работы:
 * 1. Вам нужно отображать список с произвольным типом данных.
 * 2. Вы создаёте отдельный класс, на основе `ListItem` для отображения этих данных.
 * 3. Вы создаёте экземпляр `List` и передаёте в него ссылку на созданный вами класс отображения этих данных.
 * 4. Вы заполняете список данными.
 * 5. Список автоматически создаёт экземпляры переданного класса для отображения данных.
 * 
 * @event Event.START_DRAG          Начало перетаскивания контента пользователем.
 * @event Event.STOP_DRAG           Завершение перетаскивания контента пользователем.
 * @event Event.DRAG                Перетаскивание контента пользователем.
 * @event OutOfBoundsEvent.OUT      Контент переместился за пределы доступной зоны. (При перетаскивании)
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие изначально включено.
 */
class List extends Scroller
{
    /**
     * Тип компонента `List`.
     */
    static public inline var TYPE:String = "List";

    // Приват
    private var items:Array<Dynamic> = new Array();         // Данные списка.
    private var viewsPool:Array<ListItem> = new Array();    // Пул неактивных вьюшек для повторного использования.
    private var viewsPoolLen:Int = 0;                       // Текущий размер пула неактивных вьюшек.
    private var isModified:Bool = true;                     // Используется для списка с динамическим размером.
    private var itemsPos:Array<Float> = new Array();        // Кешированная позиция элементов списка.

    /**
     * Создать список элементов.
     * @param viewsClass Класс - визуализатор элементов списка.
     */
    public function new(viewsClass:Class<ListItem>) {
        super();
        
        if (viewsClass == null)
            throw new Error("Класс визуализатора данных списка не может быть null");

        this.contentBounds = new Rectangle();
        this.componentType = TYPE;
        this.viewsClass = viewsClass;

        this.scrollH.on(Event.STOP_DRAG, onScrollStopDrag); // <-- Без этого не запустится магнетизм в конце перетаскивания
        this.scrollV.on(Event.STOP_DRAG, onScrollStopDrag);

        Utils.set(this.updateSize, List.defaultSize);
    }



    ///////////////////
    //   ЛИСТЕНЕРЫ   //
    ///////////////////

    private function onItemUpdated(item:Component, changes:BitMask):Void {
        isModified = true;
        update(false, Component.UPDATE_SIZE);
    }

    private function onScrollStopDrag(e:Event):Void {
        update(false, Component.UPDATE_SIZE);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Количество элементов в списке.
     */
    public var length(get, never):Int;
    inline function get_length():Int {
        return items.length;
    }

    /**
     * Мапа созданных вьюшек для отображения данных списка. (Индекс->`ListItem`)
     * 
     * Этот объект содержит все визуализаторы, которые в данный момент
     * используются для отображения данных списка. Вы **не должны** изменять
     * его, доступ предоставлен только для чтения.
     * 
     * пс. При динамическом размере элементов (см.: `viewsSize`) тут содержатся
     * и те вьюшки, которые не находятся на экране. Это нужно для подсчёта их
     * размеров и удаления из отображения в случае выхода за пределы списка.
     * 
     * Не может быть `null`
     */
    public var views(default, null):Dynamic = {};

    /**
     * Класс визуализатора данных списка.
     * 
     * Задаётся при создании экземпляра списка.
     * Используется списком для отображения данных.
     * Экземпляры создаются списком автоматически по мере
     * необходимости.
     * 
     * Не может быть `null`
     */
    public var viewsClass(default, null):Class<ListItem>;

    /**
     * Список параметров, передаваемых в конструктор визуализатора данных списка.
     * 
     * По умолчанию: `null`
     */
    public var viewsParams:Array<Dynamic> = null;

    /**
     * Размер элементов списка. (px)
     * 
     * Позволяет жёстко задать размер отображаемых элементов по соответствующей стороне:
     * 1. Задаёт ширину `w` для `orientation == Orientation.HORIZONTAL`.
     * 2. Задаёт высоту `h` для `orientation == Orientation.VERTICAL`.
     * 
     * Обратите внимание, что при нулевом размере, список будет создавать вьюшку для каждого
     * элемента списка, даже когда они не находятся в области отображения! Это нужно для того,
     * чтобы посчитать их размер. В списках с очень большим объёмом данных это может привести
     * к значительным провисаниям и тормозам.
     * 
     * Если вам нужно отображать произвольно большой объём данных, используйте фиксированный
     * размер элементов списка. Тогда будет создано только минимально необходимое количество
     * вьюшек для отображения.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `0` (Динамический размер элементов)
     */
    public var viewsSize(default, set):Int = 0;
    function set_viewsSize(value:Int):Int {
        if (Utils.eq(value, viewsSize))
            return value;

        isModified = true;
        viewsSize = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ между элементами списка. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `5`
     */
    public var viewsGap(default, set):Int = 5;
    function set_viewsGap(value:Int):Int {
        if (Utils.eq(value, viewsGap))
            return value;

        isModified = true;
        viewsGap = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

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

        isModified = true;
        orientation = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Примагничивание элементов списка к началу его отображения.
     * 
     * Позволяет настроить эффект автоматического выравнивания отображаемых элементов
     * списка таким образом, чтобы они ровно в нём размещались. Для использования
     * этого эффекта должен быть включен параметр `velocity`.
     * 
     * Если `null` - примагничивание отключено.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * По умолчанию: `null`
     */
    public var magnet(default, set):MagnetParams = null;
    function set_magnet(value:MagnetParams):MagnetParams {
        if (Utils.eq(value, magnet))
            return value;

        magnet = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Получить элемент списка.
     * Возвращает элемент списка по заданному индексу.
     * @param index Индкс элемента в списке.
     * @return Элемент списка.
     */
    inline public function at(index:Int):Dynamic {
        return items[index];
    }

    /**
     * Задать элемент списка по указанному индексу.
     * Записывает в список переданные данные по указанному индексу.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @param index Индекс.
     * @param value Данные.
     * @return Записанные данные.
     */
    public function set(index:Int, value:Dynamic):Void {
        isModified = true;
        items[index] = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Добавить в список данные.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @param value Данные.
     */
    public function push(value:Dynamic):Void {
        isModified = true;
        items.push(value);
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Отсортировать список.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @param func Функция сортировки.
     */
    public function sort(func:Dynamic->Dynamic->Int):Void {
        isModified = true;
        items.sort(func);
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Очистить список.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     */
    public function clear():Void {
        isModified = true;
        items = new Array();

        // Удаляем все вьюшки из отображения:
        var index = null;
        Syntax.code('for ({0} in {1}) {', index, views); // for in
            var item:ListItem = views[index];
            Utils.hide(content, item);
            Utils.delete(views[index]);
            item.data = null;
            storeItemView(item);
        Syntax.code('}'); // for end

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Поменять местами два значения в списке.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @param index1 Индекс 1.
     * @param index2 Индекс 2.
     */
    public function swap(index1:Int, index2:Int):Void {
        var tmp = items[index1];
        items[index1] = items[index2];
        items[index2] = tmp;
        isModified = true;

        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Удалить элементы списка.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @param start Начальный индекс удаляемых данных.
     * @param count Количество удаляемых элементов.
     */
    public function remove(start:Int, count:Int):Void {
        isModified = true;
        items.splice(start, count);
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
    }

    /**
     * Поиск элемента в списке.
     * Возвращает индекс первого найденного элемента в списке.
     * @param item Искомый элемент.
     * @param fromIndex Начальный индекс для поиска.
     * @return Индекс искомого элемента или `-1`, если найти не удалось.
     */
    inline public function indexOf(item:Dynamic, ?fromIndex:Int):Int {
        return items.indexOf(item, fromIndex);
    }

    /**
     * Поиск элемента в списке с конца.
     * Возвращает индекс первого найденного элемента в списке.
     * @param item Искомый элемент.
     * @param fromIndex Начальный индекс для поиска.
     * @return Индекс искомого элемента или `-1`, если найти не удалось.
     */
    inline public function lastIndexOf(item:Dynamic, ?fromIndex:Int):Int {
        return items.lastIndexOf(item, fromIndex);
    }

    /**
     * Получить ссылку на нативный массив данных.
     * Возвращает ссылку на нативный массив, используемый этим списком для хранения данных.
     * Метод предоставлен для удобства. Вы **можете** редактировать этот массив.
     * 
     * При вызове регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для повторного отображения.
     * - `Component.UPDATE_SIZE` - Для повторного позицианирования.
     * 
     * @return Нативный массив, используемый этим списком.
     */
    public function getNativeArray():Array<Dynamic> {
        isModified = true;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return items;
    }

    /**
     * Поместить вьюшку в пул для использования в будущем.
     * @param item Отработавшая вьюшка.
     */
    private function storeItemView(view:ListItem):Void {
        viewsPool[viewsPoolLen++] = view;
    }

    /**
     * Получить вьюшку для элемента списка.
     * @return Новая вьюшка.
     */
    private function getItemView():ListItem {
        if (Utils.eq(viewsPoolLen, 0))
            return untyped Type.createInstance(viewsClass, viewsParams);
        else
            return viewsPool[--viewsPoolLen];
    }

    /**
     * Получить строковое представление этого списка.
     * @return Возвращает строковое представление этого компонента.
     */
    @:keep
    override public function toString():String {
        return '[' + componentType + componentID + ' style="' + style + '" items=' + items.length + ']';
    }

    /**
     * Уничтожить список.
     * 
     * Удаляет все ссылки на скины и тему, вызывает `destroy()` всех вьюшек списка.
     * Вы не должны использовать компонент после вызова этого метода.
     * 
     * @see https://pixijs.download/dev/docs/PIXI.Container.html#destroy
     */
    @:keep
    override function destroy(?options:EitherType<Bool, ContainerDestroyOptions>) {
        // Views pool:
        var len = viewsPool.length;
        while (len-- != 0) {
            if (Utils.eq(viewsPool[len], null))
                continue;
            else
                viewsPool[len].destroy(options);
        }

        // Views:
        var index = 0;
        Syntax.code('for ({0} in {1}) {', index, views); // for in
            views[index].destroy(options);
        Syntax.code('}'); // for end

        // Other:
        viewsPoolLen = 0;

        Utils.delete(items);
        Utils.delete(views);
        Utils.delete(viewsClass);
        Utils.delete(viewsParams);
        Utils.delete(viewsPool);
        Utils.delete(magnet);

        super.destroy(options);
    }



    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв скроллера.
     */
    static public var defaultSize:SizeUpdater<List> = function(list) {
        var len = list.items.length;
        var index:Int = 0;
        var index1:Int = 0;
        var index2:Int = 0;

        // Список имеет две разных реализаций на каждый тип ориентации,
        // всего получается 4 блока кода:
        // X | Y - Фиксированный список.
        // X | Y - Динамический список.
        // Попытка совместить приводит к большому количеству добавочных
        // условий, поэтому, код решено было просто продублировать для
        // каждой оси и конкретного типа.

        // Ориентация:
        if (Utils.eq(list.orientation, Orientation.HORIZONTAL)) {

            // Горизонтальный список
            // Режим работы:
            if (list.viewsSize > 0) {

                // Список с фиксированным размером содержимого
                // Расчёт области контента:
                list.contentBounds.width = Utils.eq(len,0)?0:((list.viewsSize+list.viewsGap)*len - list.viewsGap);   
                list.contentBounds.height = list.scrollH.parent==null?list.h:Math.max(0,list.h-list.scrollH.h);

                // Обновление:
                var pre = list.contentX;
                Scroller.defaultSize(list);

                // Магнетизм:
                if (    list.magnet != null && list.magnet.enabled &&                           // 1. Магнетизм включен
                        list.velocity != null && list.velocity.allowX &&                        // 2. Движение контента включено
                        !list.isDragged &&                                                      // 3. Контент не перетаскивается
                        !list.scrollH.isDragged &&                                              // 4. Контент не скролится
                        list.contentBounds.width > 0 &&                                         // 5. Размер контента больше 0
                        list.contentX >= list.contentMinX && list.contentX <= list.contentMaxX  // 6. Контент не за пределами зоны
                ) {
                    var mp = Utils.nvl(list.magnet.position, 0);
                    var p1 = Math.min(0, Math.round((pre - mp) / list.contentBounds.width * len));
                    var p2 = Math.min(0, Math.round((list.contentX - mp) / list.contentBounds.width * len));
                    
                    // Проверка стыковки:
                    var v = p1 * (list.viewsSize+list.viewsGap) - mp;
                    var speed = list.velocity.speed.len();
                    if (    Utils.eq(p1, p2) &&                                                 // В рамках точки
                            Utils.noeq(Utils.sign(v-list.contentX), Utils.sign(v-pre)) &&       // Пересечение точки
                            speed <= Utils.nvl(list.magnet.speedMax, 50)                        // Скорость позволяет
                    ) {
                        // Стыковка:
                        list.velocity.speed.x = 0;
                        list.contentX = v;
                        list.content.x = list.pixelHinting?Math.round(v):v;
                    }
                    else {
                        // Стыковка не выполняется, подгоняем, если надо:
                        var sm = Utils.nvl(list.magnet.speedMagnet, 50);
                        if (Utils.noeq(list.contentX, v) && sm > 0 && speed < sm) {
                            if (Utils.eq(speed, 0))
                                list.velocity.speed.set(sm*Utils.sign(v-list.contentX), 0);
                            else
                                list.velocity.speed.nrm().mul(sm);

                            list.updateNext(Component.UPDATE_SIZE);
                        }
                    }
                }
                list.contentBounds.height = list.scrollH.parent==null?list.h:Math.max(0,list.h-list.scrollH.h);

                // Рендеринг
                // Отображаемые индексы:
                if (Utils.noeq(len,0)) {
                    index1 = Math.floor(-list.contentX / (list.viewsSize+list.viewsGap));
                    index2 = index1 + Math.floor(list.w / (list.viewsSize+list.viewsGap)) + 1;

                    if (index1<0) index1=0;         // Первый индекс. (Включительно)
                    if (index2>len-1) index2=len-1; // Последний индекс. (Включительно)
                }

                // По списку отображаемых вьюшек:
                // 1. Удаляем из отображения старые вьюшки, не попадающие в зону вывода.
                Syntax.code('for ({0} in {1}) {', index, list.views); // for in
                    var item:ListItem = list.views[index];
                    if (index < index1 || index > index2) {
                        Utils.hide(list.content, item);
                        Utils.delete(list.views[index]);
                        item.data = null;
                        list.storeItemView(item);
                    }
                Syntax.code('}'); // for end
                
                // По списку данных из отображаемого диапазона:
                // 1. Создаём новые вьюшки для тех, у кого их нет.
                // 2. Обновляем отображение вьюшек.
                if (Utils.noeq(len,0)) {
                    index = index1;
                    while (index <= index2) {
                        var item = list.at(index);
                        var view = list.views[index];
                        if (view == null) {
                            view = list.getItemView();
                            view.data = item;
                            list.views[index] = view;
                            list.content.addChild(view);
                        }

                        view.x = index * (list.viewsSize + list.viewsGap);
                        view.y = 0;
                        view.w = list.viewsSize;
                        view.h = list.contentBounds.height;

                        index ++;
                    }
                }
            }
            else {
                
                // Список с динамическим размером содержимого.
                // Необходимо создать/обновить вьюшки для всех данных и посчитать актуальный размер:
                if (list.isModified) {
                    var d:Float = 0;
                    var max:Float = 0;
                    while (index < len) {
                        var item = list.at(index);
                        var view = list.views[index];
                        if (view == null) {
                            view = list.getItemView();
                            view.data = item;
                            list.views[index] = view;
                        }
                        if (Utils.noeq(view.changes, 0))
                            view.update(true);
                        if (view.h > max)
                            max = view.h;
                        list.itemsPos[index] = d;
                        d += view.w + list.viewsGap;
                        index ++;
                    }
                    list.contentBounds.width = len>0?(d-list.viewsGap):0;
                    list.contentBounds.height = max;
                }

                // Обновление:
                var prev = list.contentX;
                Scroller.defaultSize(list);

                // Магнетизм:
                if (    list.magnet != null && list.magnet.enabled &&                           // 1. Магнетизм включен
                        list.velocity != null && list.velocity.allowX &&                        // 2. Движение контента включено
                        !list.isDragged &&                                                      // 3. Контент не перетаскивается
                        !list.scrollH.isDragged &&                                              // 4. Контент не скролится
                        list.contentBounds.width > 0 &&                                         // 5. Размер контента больше 0
                        list.contentX >= list.contentMinX && list.contentX <= list.contentMaxX  // 6. Контент не за пределами зоны
                ) {
                    // Находим ближайшую точку стыковки:
                    var min:Float = 9999999999999;
                    var mp = Utils.nvl(list.magnet.position, 0);
                    var p:Float = 0;
                    index = 0;
                    while (index < len) {
                        var dist = Math.abs(-list.contentX - (list.itemsPos[index] + mp));
                        if (dist < min) {
                            min = dist;
                            p = -(list.itemsPos[index] + mp);
                            index ++;
                            continue;
                        }
                        
                        break;
                    }
                    
                    // Стыковка:
                    var speed = list.velocity.speed.len();
                    if (    Utils.noeq(Utils.sign(p-prev), Utils.sign(p-list.contentX)) &&  // Пересечение точки
                            speed <= Utils.nvl(list.magnet.speedMax, 50)                    // Скорость позволяет
                    ) {
                        // Захвачен:
                        list.velocity.speed.x = 0;
                        list.contentX = p;
                        list.content.x = list.pixelHinting?Math.round(p):p;
                    }
                    else {
                        // Стыковка не выполняется, подгоняем, если надо:
                        var sm = Utils.nvl(list.magnet.speedMagnet, 50);
                        if (Utils.noeq(list.contentX, p) && sm > 0 && speed < sm) {
                            if (Utils.eq(speed, 0))
                                list.velocity.speed.set(sm*Utils.sign(p-list.contentX), 0);
                            else
                                list.velocity.speed.nrm().mul(sm);

                            list.updateNext(Component.UPDATE_SIZE);
                        }
                    }
                }

                // Рендеринг:
                Syntax.code('for ({0} in {1}) {', index, list.views); // for in
                    var item:ListItem = list.views[index];
                    if (index < len) {
                        var d = item.x + list.contentX;
                        if (d > list.outW || d + item.w < 0) {
                            // За пределами отображения:
                            if (Utils.eq(item.parent, list.content))
                                list.content.removeChild(item);
                        }
                        else {
                            // В пределах отображения:
                            if (Utils.noeq(item.parent, list.content))
                                list.content.addChild(item);

                            item.x = list.itemsPos[index];
                            item.y = 0;
                        }
                    }
                    else {
                        // Эта вьюшка больше не нужна:
                        Utils.hide(list.content, item);
                        Utils.delete(list.views[index]);
                        item.data = null;
                        list.storeItemView(item);
                    }
                Syntax.code('}'); // for end
            }
        }
        else {

            // Вертикальный список
            // Режим работы:
            if (list.viewsSize > 0) {

                // Список с фиксированным размером содержимого
                // Расчёт области контента:
                list.contentBounds.width = list.scrollV.parent==null?list.w:Math.max(0,list.w-list.scrollV.w);
                list.contentBounds.height = Utils.eq(len,0)?0:((list.viewsSize+list.viewsGap)*len - list.viewsGap);   

                // Обновление:
                var pre = list.contentY;
                Scroller.defaultSize(list);

                // Магнетизм:
                if (    list.magnet != null && list.magnet.enabled &&                           // 1. Магнетизм включен
                        list.velocity != null && list.velocity.allowY &&                        // 2. Движение контента включено
                        !list.isDragged &&                                                      // 3. Контент не перетаскивается
                        !list.scrollV.isDragged &&                                              // 4. Контент не скролится
                        list.contentBounds.height > 0 &&                                        // 5. Размер контента больше 0
                        list.contentY >= list.contentMinY && list.contentY <= list.contentMaxY  // 6. Контент не за пределами зоны
                ) {
                    var mp = Utils.nvl(list.magnet.position, 0);
                    var p1 = Math.min(0, Math.round((pre - mp) / list.contentBounds.height * len));
                    var p2 = Math.min(0, Math.round((list.contentY - mp) / list.contentBounds.height * len));
                    
                    // Проверка стыковки:
                    var v = p1 * (list.viewsSize+list.viewsGap) - mp;
                    var speed = list.velocity.speed.len();
                    if (    Utils.eq(p1, p2) &&                                                 // В рамках точки
                            Utils.noeq(Utils.sign(v-list.contentY), Utils.sign(v-pre)) &&       // Пересечение точки
                            speed <= Utils.nvl(list.magnet.speedMax, 50)                        // Скорость позволяет
                    ) {
                        // Стыковка:
                        list.velocity.speed.y = 0;
                        list.contentY = v;
                        list.content.y = list.pixelHinting?Math.round(v):v;
                    }
                    else {
                        // Стыковка не выполняется, подгоняем, если надо:
                        var sm = Utils.nvl(list.magnet.speedMagnet, 50);
                        if (Utils.noeq(list.contentY, v) && sm > 0 && speed < sm) {
                            if (Utils.eq(speed, 0))
                                list.velocity.speed.set(0, sm*Utils.sign(v-list.contentY));
                            else
                                list.velocity.speed.nrm().mul(sm);

                            list.updateNext(Component.UPDATE_SIZE);
                        }
                    }
                }
                list.contentBounds.width = list.scrollV.parent==null?list.w:Math.max(0,list.w-list.scrollV.w);

                // Рендеринг
                // Отображаемые индексы:
                if (Utils.noeq(len,0)) {
                    index1 = Math.floor(-list.contentY / (list.viewsSize+list.viewsGap));
                    index2 = index1 + Math.floor(list.h / (list.viewsSize+list.viewsGap)) + 1;

                    if (index1<0) index1=0;         // Первый индекс. (Включительно)
                    if (index2>len-1) index2=len-1; // Последний индекс. (Включительно)
                }

                // По списку отображаемых вьюшек:
                // 1. Удаляем из отображения старые вьюшки, не попадающие в зону вывода.
                Syntax.code('for ({0} in {1}) {', index, list.views); // for in
                    var item:ListItem = list.views[index];
                    if (index < index1 || index > index2) {
                        Utils.hide(list.content, item);
                        Utils.delete(list.views[index]);
                        item.data = null;
                        list.storeItemView(item);
                    }
                Syntax.code('}'); // for end
                
                // По списку данных из отображаемого диапазона:
                // 1. Создаём новые вьюшки для тех, у кого их нет.
                // 2. Обновляем отображение вьюшек.
                index = index1;
                if (Utils.noeq(len,0)) {
                    while (index <= index2) {
                        var item = list.at(index);
                        var view = list.views[index];
                        if (view == null) {
                            view = list.getItemView();
                            view.data = item;
                            list.views[index] = view;
                            list.content.addChild(view);
                        }

                        view.x = 0;
                        view.y = index * (list.viewsSize + list.viewsGap);
                        view.w = list.contentBounds.width;
                        view.h = list.viewsSize;

                        index ++;
                    }
                }
            }
            else {
                
                // Список с динамическим размером содержимого.
                // Необходимо создать/обновить вьюшки для всех данных и посчитать актуальный размер:
                if (list.isModified) {
                    var d:Float = 0;
                    var max:Float = 0;
                    while (index < len) {
                        var item = list.at(index);
                        var view = list.views[index];
                        if (view == null) {
                            view = list.getItemView();
                            view.data = item;
                            list.views[index] = view;
                        }
                        if (Utils.noeq(view.changes, 0))
                            view.update(true);
                        if (view.w > max)
                            max = view.w;
                        list.itemsPos[index] = d;
                        d += view.h + list.viewsGap;
                        index ++;
                    }
                    list.contentBounds.width = max;
                    list.contentBounds.height = len>0?(d-list.viewsGap):0;
                }

                // Обновление:
                var prev = list.contentY;
                Scroller.defaultSize(list);

                // Магнетизм:
                if (    list.magnet != null && list.magnet.enabled &&                           // 1. Магнетизм включен
                        list.velocity != null && list.velocity.allowY &&                        // 2. Движение контента включено
                        !list.isDragged &&                                                      // 3. Контент не перетаскивается
                        !list.scrollV.isDragged &&                                              // 4. Контент не скролится
                        list.contentBounds.height > 0 &&                                        // 5. Размер контента больше 0
                        list.contentY >= list.contentMinY && list.contentY <= list.contentMaxY  // 6. Контент не за пределами зоны
                ) {
                    // Находим ближайшую точку стыковки:
                    var min:Float = 9999999999999;
                    var mp = Utils.nvl(list.magnet.position, 0);
                    var p:Float = 0;
                    index = 0;
                    while (index < len) {
                        var dist = Math.abs(-list.contentY - (list.itemsPos[index] + mp));
                        if (dist < min) {
                            min = dist;
                            p = -(list.itemsPos[index] + mp);
                            index ++;
                            continue;
                        }
                        
                        break;
                    }
                    
                    // Стыковка:
                    var speed = list.velocity.speed.len();
                    if (    Utils.noeq(Utils.sign(p-prev), Utils.sign(p-list.contentY)) &&  // Пересечение точки
                            speed <= Utils.nvl(list.magnet.speedMax, 50)                    // Скорость позволяет
                    ) {
                        // Захвачен:
                        list.velocity.speed.y = 0;
                        list.contentY = p;
                        list.content.y = list.pixelHinting?Math.round(p):p;
                    }
                    else {
                        // Стыковка не выполняется, подгоняем, если надо:
                        var sm = Utils.nvl(list.magnet.speedMagnet, 50);
                        if (Utils.noeq(list.contentY, p) && sm > 0 && speed < sm) {
                            if (Utils.eq(speed, 0))
                                list.velocity.speed.set(0, sm*Utils.sign(p-list.contentY));
                            else
                                list.velocity.speed.nrm().mul(sm);

                            list.updateNext(Component.UPDATE_SIZE);
                        }
                    }
                }

                // Рендеринг:
                Syntax.code('for ({0} in {1}) {', index, list.views); // for in
                    var item:ListItem = list.views[index];
                    if (index < len) {
                        var d = item.y + list.contentY;
                        if (d > list.outH || d + item.h < 0) {
                            // За пределами отображения:
                            if (Utils.eq(item.parent, list.content))
                                list.content.removeChild(item);
                        }
                        else {
                            // В пределах отображения:
                            if (Utils.noeq(item.parent, list.content))
                                list.content.addChild(item);

                            item.x = 0;
                            item.y = list.itemsPos[index];
                        }
                    }
                    else {
                        // Эта вьюшка больше не нужна:
                        Utils.hide(list.content, item);
                        Utils.delete(list.views[index]);
                        item.data = null;
                        list.storeItemView(item);
                    }
                Syntax.code('}'); // for end
            }
        }

        // Обновление завершено:
        list.isModified = false;
    }
}

/**
 * Параметры "примагничивания" элементов списка к сетке.
 * 
 * Позволяет настроить автоматическое выравнивание первого, отображаемого
 * элемента в списке по нулевой координате. 
 */
typedef MagnetParams =
{
    /**
     * Включено.
     */
    @:optional var enabled:Bool;

    /**
     * Позиция примагничивания. (px)
     * 
     * Позволяет настроить точку примагничивания в компоненте, которая по умолчанию равна `0`.
     * (Левый/верхний край компонента)
     * 
     * Если не задано, используется значение по умолчанию: `0`
     */
    @:optional var position:Int;

    /**
     * Скорость примагничивания. (px/sec)
     * 
     * Двигает контент с этой скоростью или более к ближайшей точке привязки.
     * Обратите внимание, что это значение не должно превышать `speedMax`, иначе
     * контент никогда не сможет примагнититься и будет вечно дрожать над точкой.
     * 
     * Если не задано, используется значение по умолчанию: `50`
     */
    @:optional var speedMagnet:Float;

    /**
     * Максимальная скорость для "стыковки". (px/sec)
     * Если контент движется быстрее, он пролетает мимо игнорируя точку привязки.
     * 
     * Если не задано, используется значение по умолчанию: `50`
     */
    @:optional var speedMax:Float;
}