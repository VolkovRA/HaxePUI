package pui;

import js.Browser;
import js.Syntax;
import haxe.DynamicAccess;
import pui.ui.Button;
import pui.ui.Label;
import pui.ui.Component;
import pui.ui.ScrollBar;
import pui.ui.Scroller;
import pui.pixi.PixiEvent;
import pui.events.WheelEvent;
import pui.events.ThemeEvent;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import pixi.core.math.Point;
import pixi.core.text.Text;
import pixi.interaction.EventEmitter;

/**
 * Тема оформления.
 * Каждый элемент интерфейса **привязан** к какой-то теме. Этот класс также обеспечивает
 * базовую функциональность всех компонентов по их обновлению и перерисовке.
 * 
 * Тема используется для:
 * - Кастомизаций всех элементов интерфейса, выполняя роль фабрики скинов и стилей.
 * - Хранение всех используемых текстур, стилей, шейдеров и т.п. в одном месте, для
 *     их повторного, многократного использования всеми элементами интерфейса.
 * - Быстрого переключения используемой темы оформления.
 * - Внутренней реализацией, для обеспечения работы элементов интерфейса. (Автообновление)
 * 
 * Вы **должны** расширить этот класс своим и добавить все стили для используемых вами
 * элементов интерфейса, с помощью метода: `addStyle()`.
 * 
 * Вы **должны** назначить созданную тему в статическое свойство `Theme.current`, чтобы
 * новые компоненты интерфейса смогли получить доступ к используемой теме.
 * 
 * Вы **можете** назначить любой экземпляр созданной темы каждому компоненту интерфейса
 * отдельно, чтобы использовать несколько тем одновременно.
 * 
 * @event ThemeEvent.UPDATE_START   Испускается в каждом кадре перед запуском нового цикла обновления всех компонентов.
 * @event ThemeEvent.UPDATE_FINISH  Испускается в каждом кадре после завершения цикла обновления всех компонентов.
 */
class Theme extends EventEmitter
{
    static private inline var COLOR_BLACK:Int = 0x000000;
    static private inline var COLOR_GRAY_DARK:Int = 0x212121;
    static private inline var COLOR_GRAY:Int = 0x303030;
    static private inline var COLOR_GRAY_BRIGHT:Int = 0x424242;
    static private var POINT:Point = new Point();
    static private var errors:DynamicAccess<Bool> = {};

    /**
     * Создать новую тему.
     * @param application Экземпляр приложения pixi, который выполняет рендеринг гуи данной темы.
     * @param name Название темы.
     */
    public function new(application:Application, name:String = "Новая тема") {
        super();
        
        this.application = application;
        this.name = name;

        // События:
        application.renderer.on(PixiEvent.PRE_RENDER, onUpdateUI);
        application.renderer.view.addEventListener("wheel", onWheel);
    }    



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Название темы.
     * Не несёт функциональной нагрузки.
     * 
     * Может быть `null`.
     */
    public var name:String;

    /**
     * Экземпляр приложения pixi, который выполняет рендеринг гуи данной темы.
     * 
     * Эта ссылка используется для доступа к событиям пре/пост рендеринга, для 
     * автоматического обновления гуи компонентов при их изменении.
     * 
     * Не может быть `null`.
     */
    public var application(default, null):Application;
    
    /**
     * Все доступные стили темы.
     * 
     * Список содержит зарегистрированные стили для всех типов компонентов данной темы.
     * Для добавления элементов в список воспользуйтесь методом: `addStyle()`.
     * 
     * *Доступ предоставлен для удобства.*
     * 
     * Не может быть `null`.
     */
    public var styles(default, null):DynamicAccess<Dynamic->Void> = {};

    /**
     * Номер кадра.
     * 
     * Этот счётчик увеличивается на `1` в каждом цикле рендера **после**  
     * завершения обновления всех компонентов этой темы.
     * 
     * По умолчанию: `1`.
     */
    public var frame(default, null):Int = 1;

    /**
     * Максимальное количество обновлений одного компонента за один цикл рендера.
     * 
     * Система гуи компонентов устроена так, что бы свести к минимуму количество 
     * перерисовок отдельно взятого компонента за один цикл рендера. (В идеале 1)
     * Для этого используются маска изменений `Component.changes` и метод `Component.update()`,
     * для отложенного вызова обновления. Однако, при некоторых условиях, компонент
     * **может** обновиться два или более раз за цикл. Например, если обновление
     * компонента провоцирует повторное его же обновление. В таком случае может даже
     * произойти "dead loop" - бесконечный цикл, который полностью завесит рендер
     * и исчерпает всю доступную память. Это значение используется для того, что бы
     * избежать такого сценария.
     * 
     * Достижение этого количества обновлений за цикл будет явно свидетельствовать
     * о проблемах в спроектированном вами интерфейсе. В идеале, каждый ваш компонент
     * не должен обновляться более одного раза за кадр.
     * 
     * Если количество обновлений компонента достигает этого значения, компонент
     * больше не обновляется в текущем цикле и пропускается, а в консоль пишется
     * сообщение об ошибке. (Исключение не выбрасывается и рендер продолжается)
     * 
     * По умолчанию: `100`.
     */
    public var updateMax:Int = 100;

    /**
     * Прошедшее время с момента последнего цикла обновления. (sec)
     * 
     * Расчитывается заного перед каждым новым циклом рендера и используется
     * для анимирования компонентов.
     * 
     * По умолчанию: `0`
     */
    public var dt(default, null):Float = 0;

    /**
     * Список компонентов для обновления в текущем цикле рендера.
     * Используется внутренней реализацией для обновления компонентов.
     */
    @:noDoc
    @:noCompletion
    private var updateItems:Array<Component> = new Array();

    /**
     * Количество компонентов для обновления в текущем цикле рендера.
     * Используется внутренней реализацией для обновления компонентов.
     */
    @:noDoc
    @:noCompletion
    private var updateLen:Int = 0;

    /**
     * Количество компонентов для обновления в следующем цикле рендера.
     * Используется внутренней реализацией для обновления компонентов.
     */
    @:noDoc
    @:noCompletion
    private var updateLenNext:Int = 0;

    /**
     * Список компонентов для обновления в следующем цикле рендера.
     * Используется внутренней реализацией для обновления компонентов.
     */
    @:noDoc
    @:noCompletion
    private var updateItemsNext:Array<Component> = new Array();

    /**
     * Список изменений в компонентах для обновления в следующем цикле рендера.
     * Этот массив связан с `updateItemsNext`.
     */
    @:noDoc
    @:noCompletion
    private var updateItemsFlagsNext:Array<BitMask> = new Array();

    /**
     * Дата последнего цикла обновления с момента запуска приложения. (sec)
     * Используется внутренней реализацией для расчёта прошедшего времени.
     */
    private var timeUPD:Float = Utils.uptime() / 1000;

    /**
     * Список слушателей событий колёсика мыши: `ComponentID`->`Component`.
     */
    @:noDoc
    @:noCompletion
    private var wheelListeners:Dynamic = {};



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Добавить компонент в список слушателей событий колёсика мыши.
     * @param component Компонент.
     */
    @:allow(pui.ui.Component) 
    @:noDoc
    @:noCompletion
    private function addWheelListener(component:Component):Void {
        wheelListeners[component.componentID] = component;
    }

    /**
     * Удалить компонент из списка слушателей колёсика мыши.
     * @param component Компонент.
     */
    @:allow(pui.ui.Component) 
    @:noDoc
    @:noCompletion
    private function removeWheelListener(component:Component):Void {
        Utils.delete(wheelListeners[component.componentID]);
    }

    /**
     * Обработка события скролла колёсиком мыши.
     * @param e Событие скрола.
     */
    private function onWheel(e:js.html.WheelEvent):Void {

        // Обработка слушателей колёсика мыши.
        // Координаты:
        application.renderer.plugins.interaction.mapPositionToPoint(POINT, e.x, e.y);
        var x = POINT.x;
        var y = POINT.y;

        // Получаем список активных слушателей:
        var arr = new Array<WheelListener>();
        var key:Int = null;
        var item:Component = null;
        Syntax.code("for ({0} in {1}) {", key, wheelListeners); // for in
            item = wheelListeners[key];

            // Удаление мёртвых слушателей:
            if (Utils.noeq(item.theme, this) || !item.inputWheel) {
                Utils.delete(wheelListeners[item.componentID]);
                Syntax.code("continue");
            }

            // Пропуск неподходящих слушателей:
            var depth = Utils.getDepth(item, application.stage, true);
            if (!item.enabled || depth == -1)
                Syntax.code("continue");

            // Проверка на попадание курсора в область компонента:
            POINT.x = x;
            POINT.y = y;
            item.toLocal(POINT, null, POINT);
            if (POINT.x < 0 || POINT.x > item.w || POINT.y < 0 || POINT.y > item.h)
                Syntax.code("continue");
            
            // Добавление активного слушателя:
            arr.push({ depth:depth, item:item });
        Syntax.code("}"); // for end

        // Наличие активных слушателей:
        var len = arr.length;
        if (Utils.eq(len, 0))
            return;
        
        // Рассылка события, начиная с самого глубокого: (Всплытие)
        arr.sort(sortWheelItems);
        
        var cd = arr[len-1].depth; // current depth
        var canceled = false;
        while (Utils.noeq(len--, 0)) {
            
            // Отмена диспетчерезации предыдущим получателем события.
            // 
            // На одном и том же уровне глубины событие всё ещё отрабатывает,
            // так как мы не знаем, какой из компонентов находится "выше".
            // Такая ситуация может произойти, когда оба компонента имеют
            // одинаковую глубину но разную цепочку родителей.
            // 
            // В текущей реализации используется компромисное решение для
            // большей скорости работы, что бы не проверять всё дерево целиком,
            // проверяется только цепочка родителей каждого из компонентов.
            //
            // Возможная проблема компромиса - получение события скролла двумя или
            // более компонентами, расположенными на одном уровне вложенности и
            // друг над другом. Для решения этого вы можете просто расставить их
            // в стороны, изменить глубину их вложенности или просто скрыть
            // не нужные компоненты.
            if (canceled && arr[len].depth < cd)
                return;

            // Отправка события:
            item = arr[len].item;
            cd = arr[len].depth;

            var we = WheelEvent.get(WheelEvent.WHEEL, item);
            we.native = e;
            item.emit(WheelEvent.WHEEL, we);

            if (!we.bubbling)
                canceled = true;
            
            WheelEvent.store(we);
        }
    }

    /**
     * Сортировка активных слушателей колёсика мыши.
     */
    @:noDoc
    @:noCompletion
    private function sortWheelItems(x:WheelListener, y:WheelListener):Int {
        if (x.depth > y.depth)
            return 1;
        if (x.depth < y.depth)
            return -1;

        if (x.item.componentID > y.item.componentID)
            return 1;
        else
            return -1;
    }

    /**
     * Обновление компонентов интерфейса.
     * 
     * Эта функция производит обновление всех компонентов, свзязанных с данной темой и у
     * которых был вызва метод: `Component.update()`.
     */
    @:noDoc
    @:noCompletion
    private function onUpdateUI():Void {

        // Запуск цикла рендера.
        // Разное:
        var updates:Int = 0;

        // Событие начала:
        var e = ThemeEvent.get(ThemeEvent.UPDATE_START, this);
        emit(ThemeEvent.UPDATE_START, e);
        ThemeEvent.store(e);

        // Прошедшее время:
        var ct = Utils.uptime() / 1000;
        dt = ct - timeUPD;
        timeUPD = ct;

        // Добавляем компоненты из предыдущего, отложенного вызова:
        var i = 0;
        while (i < updateLenNext) {
            updateItemsNext[i].update(false, updateItemsFlagsNext[i]);
            updateItemsNext[i] = null;
            i ++;
        }
        updateLenNext = 0;

        // Основной цикл обновления.
        // 1. Количество в списке может увеличиваться по мере работы цикла.
        // 2. Список может содержать дубли.

        i = 0;
        while (i < updateLen) {
            if (    // Пропускаем уже обновлённые:
                    Utils.noeq(updateItems[i].changes, 0) &&

                    // Если компонент присутствует в списке несколько раз - обновим только последнего:
                    Utils.eq(updateItems[i].themeRenderIndex, i) &&

                    // Компонент мог сменить тему и уже не относится к нам:
                    Utils.eq(updateItems[i].theme, this)   
            ) {
                if (updateItems[i].themeRenderCount < updateMax) {
                    updateItems[i].onComponentUpdate();
                    updates ++;
                }
                else {
                    Browser.console.error("Компонент " + updateItems[i].toString() + " достиг лимита количества обновлений в одном цикле рендера (frame=" + frame + ") и будет пропущен, проверьте свойство: pui.Theme.updateMax", updateItems[i]);
                }
            }

            updateItems[i++] = null;
        }

        updateLen = 0;
        frame ++;

        // Событие завершения:
        var e = ThemeEvent.get(ThemeEvent.UPDATE_FINISH, this);
        e.updates = updates;
        emit(ThemeEvent.UPDATE_FINISH, e);
        ThemeEvent.store(e);
    }

    /**
     * Добавить компонент для обновления в текущем цикле рендера.
     * Метод используется внутренней реализацией для обновления компонентов.
     * 
     * @param component Компонент.
     */
    @:allow(pui.ui.Component) 
    @:noDoc
    @:noCompletion
    private function addUpdate(component:Component):Void {
        if (Utils.noeq(component.themeRenderFrame, frame)) {
            component.themeRenderFrame = frame;
            component.themeRenderCount = 0;
        }
        
        component.themeRenderIndex = updateLen;
        updateItems[updateLen++] = component;
    }

    /**
     * Добавить компонент для обновления в следующем цикле рендера.
     * Метод используется внутренней реализацией для обновления компонентов.
     * 
     * @param component Компонент.
     * @param flags Будущие изменения.
     */
    @:allow(pui.ui.Component) 
    @:noDoc
    @:noCompletion
    private function addUpdateNext(component:Component, flags:BitMask):Void {
        updateItemsNext[updateLenNext] = component;
        updateItemsFlagsNext[updateLenNext] = flags;
        updateLenNext ++;
    }

    /**
     * Стилизовать компонент.
     * Выполняет стилизацию переданного компонента в соответствии с настройками темы.
     * 
     * *Этот метод вызывается автоматически при созданий нового компонента этой темы.*
     * 
     * @param component Стилизуемый компонент.
     */
    public function apply(component:Component):Void {
        if (Utils.eq(component, null))
            return;

        var f = styles[getKey(component.componentType, component.style)];
        if (f != null) {
            f(component);
            return;
        }

        f = styles[getKey(component.componentType)];
        if (f != null) {
            f(component);
            return;
        }

        unknownStyle(component);

        // Ислючаем дубли ошибок в выводе:
        var str = component.toString() + " - Не найден стиль оформления компонента";
        if (errors[str])
            return;

        errors[str] = true;
        Browser.console.error(str);
    }

    /**
     * Добавить новый стиль компонента в эту тему.
     * Регистрирует указанную функцию декоратора для заданного типа и стиля компонента.
     * - Вызов игнорируется, если тип компонента не указан. (`null`)
     * - Вы можете передать имя стиля как `null`, тогда обработчик будет использоваться как стиль *по умолчанию*.
     * 
     * @param componentType Тип компонента. Пример: `Label`. 
     * @param style Имя стиля. Пример: `PanelTitle`.
     * @param callback Функция стилизации.
     */
    public function addStyle<T:Component>(componentType:String, style:String, callback:T->Void):Void {
        if (Utils.eq(componentType, null))
            return;
        
        styles[getKey(componentType, style)] = callback;
    }

    /**
     * Дефолтное оформление компонента.
     * Используется для подкраски компонентов, стиль которых не задан.
     * @param component Компонент.
     */
    public function unknownStyle(component:Component):Void {
        if (Utils.eq(component.componentType, Label.TYPE))              unknownStyleLabel(untyped component);
        else if (Utils.eq(component.componentType, Button.TYPE))        unknownStyleButton(untyped component);
        else if (Utils.eq(component.componentType, ScrollBar.TYPE))     unknownStyleScrollBar(untyped component);
        else if (Utils.eq(component.componentType, Scroller.TYPE))      unknownStyleScroller(untyped component);
        else {
            var bg = new Graphics();
            bg.beginFill(COLOR_GRAY_DARK);
            bg.drawRect(0, 0, 10, 10);
            component.skinBg = bg; 
        }
    }

    /**
     * Дефолтное оформление `Label`.
     * Используется для подкраски компонентов, стиль которых не задан.
     * @param label Текстовая метка.
     */
    public function unknownStyleLabel(label:Label):Void {
        if (Utils.eq(label.skinText, null)) { label.skinText = new Text(""); label.skinText.style.fontSize=16; label.skinText.style.fill = "white"; };
        if (Utils.eq(label.w, 0))           label.w = 80;
        if (Utils.eq(label.h, 0))           label.h = 20;
    }

    /**
     * Дефолтное оформление `Button`.
     * Используется для подкраски компонентов, стиль которых не задан.
     * @param button Кнопка.
     */
    public function unknownStyleButton(button:Button):Void {
        var bg = new Graphics();
        bg.beginFill(COLOR_GRAY);
        bg.drawRect(0, 0, 10, 10);

        var hover = new Graphics();
        hover.beginFill(COLOR_GRAY_BRIGHT);
        hover.drawRect(0, 0, 10, 10);

        var press = new Graphics();
        press.beginFill(COLOR_GRAY_BRIGHT);
        press.drawRect(0, 0, 10, 10);

        if (Utils.eq(button.label, null))       button.label = new Label();
        if (Utils.eq(button.skinBg, null))      button.skinBg = bg;
        if (Utils.eq(button.skinBgHover, null)) button.skinBgHover = hover;
        if (Utils.eq(button.skinBgPress, null)) button.skinBgPress = press;
        if (Utils.eq(button.w, 0))              button.w = 100;
        if (Utils.eq(button.h, 0))              button.h = 40;
    }

    /**
     * Дефолтное оформление `ScrollBar`.
     * Используется для подкраски компонентов, стиль которых не задан.
     * @param scroll Полоса прокрутки.
     */
    public function unknownStyleScrollBar(scroll:ScrollBar):Void {
        if (Utils.eq(scroll.skinScroll, null)) {
            var bg = new Graphics();
            bg.interactive = true;
            bg.beginFill(COLOR_GRAY_DARK);
            bg.drawRect(0, 0, 10, 10);
            scroll.skinScroll = bg;
        };

        if (scroll.pointMode) {
            if (Utils.eq(scroll.thumb, null))       { scroll.thumb = new Button(); scroll.thumb.w = 12; scroll.thumb.h = 12; scroll.thumb.debug = true;};
            if (Utils.eq(scroll.padding, null))     scroll.padding = { top:6, left:6, right:6, bottom:6 };

            if (Utils.eq(scroll.orientation, Orientation.HORIZONTAL)) {
                if (Utils.eq(scroll.w, 0))          scroll.w = 140;
                if (Utils.eq(scroll.h, 0))          scroll.h = 17;
            }
            else {
                if (Utils.eq(scroll.w, 0))          scroll.w = 17;
                if (Utils.eq(scroll.h, 0))          scroll.h = 140;
            }
        }
        else {
            if (Utils.eq(scroll.thumb, null))       { scroll.thumb = new Button(); scroll.thumb.w = 13; scroll.thumb.h = 13; };
            if (Utils.eq(scroll.decBt, null))       { scroll.decBt = new Button(); scroll.decBt.w = 17; scroll.decBt.h = 17; scroll.decBt.autopress.enabled = true; };
            if (Utils.eq(scroll.incBt, null))       { scroll.incBt = new Button(); scroll.incBt.w = 17; scroll.incBt.h = 17; scroll.incBt.autopress.enabled = true; };
            if (Utils.eq(scroll.padding, null))     scroll.padding = { top:2, left:2, right:2, bottom:2 };

            if (Utils.eq(scroll.orientation, Orientation.HORIZONTAL)) {
                if (Utils.eq(scroll.w, 0))          scroll.w = 140;
                if (Utils.eq(scroll.h, 0))          scroll.h = 17;
            }
            else {
                if (Utils.eq(scroll.w, 0))          scroll.w = 17;
                if (Utils.eq(scroll.h, 0))          scroll.h = 140;
            }
        }
    }

    /**
     * Дефолтное оформление `Scroller`.
     * Используется для подкраски компонентов, стиль которых не задан.
     * @param scroller Скроллер.
     */
    public function unknownStyleScroller(sc:Scroller):Void {
        if (Utils.eq(sc.skinBg, null)) {
            var bg = new Graphics();
            bg.interactive = true;
            bg.beginFill(COLOR_GRAY_DARK);
            bg.drawRect(0, 0, 10, 10);
            sc.skinBg = bg;
        };

        if (Utils.eq(sc.w, 0))
            sc.w = 150;
        if (Utils.eq(sc.h, 0))
            sc.h = 150;
    }

    /**
     * Получить строковой ключ для поиска стиля.
     * Ключ формируется очень просто, для удобства это сделано в одном месте.
     * 
     * @param componentType Тип компонента. (Не должен быть `null`)
     * @param style Имя стиля. (Может быть `null` для стиля: *по умолчанию*)
     * @return Строковой ключ для поиска стиля.
     */
    final private inline function getKey(componentType:String, style:String = null):String {
        return componentType + (Utils.eq(style, null) ? "" : ("_" + style));
    }

    /**
     * Уничтожить тему.
     * Не используйте тему после того, как вы вызвали этот метод.
     */
    public function destroy():Void {
        application.renderer.off(PixiEvent.POST_RENDER, onUpdateUI);
        application.renderer.view.removeEventListener("wheel", onWheel);

        styles = null;
        application = null;
        updateItems = null;
        updateItemsNext = null;
        updateItemsFlagsNext = null;
        wheelListeners = null;
        updateLen = 0;
        updateLenNext = 0;
    }



    /////////////////
    //   СТАТИКА   //
    /////////////////

    /**
     * Текущая, используемая тема.
     * Перед созданием gui компонентов вы **должны** создать тему!
     * 
     * Это свойство считывается всеми новыми компонентами интерфейса при их создании, если им не указано иное.
     * Замена или изменение этой темы не изменит уже созданные компоненты, но повлияет на новые.
     * Для изменения темы уже созданных компонентов, вы можете переключить их свойство `Component.theme`.
     * 
     * По умолчанию: `null`.
     */
    static public var current:Theme = null;
}

@:noDoc
@:noCompletion
private typedef WheelListener =
{
    var depth:Int;
    var item:Component;
}