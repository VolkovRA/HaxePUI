package pui;

import js.Browser;
import haxe.DynamicAccess;
import pui.ScrollBar;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;

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
 */
class Theme
{
    static private inline var COLOR_BLACK:Int = 0x000000;
    static private inline var COLOR_GRAY_DARK:Int = 0x212121;
    static private inline var COLOR_GRAY:Int = 0x303030;
    static private inline var COLOR_GRAY_BRIGHT:Int = 0x424242;
    static private var errors:DynamicAccess<Bool> = {};

    /**
     * Создать новую тему.
     * @param application Экземпляр приложения pixi, который выполняет рендеринг гуи данной темы.
     * @param name Название темы.
     */
    public function new(application:Application, name:String = "Новая тема") {
        this.application = application;
        this.name = name;

        // События:
        application.renderer.on(Event.PRE_RENDER, onUpdateUI);
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
     * Количество обновлённых компонентов в последнем цикле рендера.
     * 
     * Содержит число вызовов метода: `Component.onComponentUpdate` этой темой в рамках последнего цикла рендера.
     * Это значение не учитывает ручное обновление компонентов: `Component.update(true)`.
     * Может быть полезно для отслеживания количества перерисованных компонентов за один кадр.
     * 
     * *пс. Это значение сбрасывается перед каждым, новым циклом рендера.*
     * 
     * По умолчанию: `0`.
     */
    public var updateCount:Int = 0;

    /**
     * Колбек начала цикла обновления: `function(Theme):Void`
     * 
     * Если задан, вызывается перед началом обновления всех компонентов этой темы во время цикла рендера.
     * Может быть полезно, когда необходимо собрать статистику о количестве перерисованных компонентов.
     * 
     * *пс. Этот вызов работает в рамках события pixi: `Event.PRE_RENDER`.*
     * 
     * По умолчанию: `null`.
     * 
     * @see `Theme.updateCount`
     * @see `Theme.onUpdateEnd`
     */
    public var onUpdateStart:Dynamic->Void = null;

    /**
     * Колбек завершения обновления всех компонентов этой темы: `function(Theme):Void`
     * 
     * Если задан, вызывается после завершения обновления всех компонентов во время цикла рендера.
     * Может быть полезно, когда необходимо собрать статистику о количестве перерисованных компонентов.
     * Обратите внимание, что новые вызовы `Component.update()` приведут к обновлению этих компонентов
     * уже в следующем кадре.
     * 
     * *пс. Этот вызов работает в рамках события pixi: `Event.PRE_RENDER`.*
     * 
     * По умолчанию: `null`.
     * 
     * @see `Theme.updateCount`
     * @see `Theme.onUpdateStart`
     */
    public var onUpdateEnd:Dynamic->Void = null;

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



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Обновление компонентов интерфейса.
     * 
     * Эта функция производит обновление всех компонентов свзяанных с данной темой и у
     * которых был вызва метод: `Component.update()`.
     */
    @:noDoc
    @:noCompletion
    private function onUpdateUI():Void {
        if (Utils.noeq(onUpdateStart, null))
            onUpdateStart(this);

        // Обновление всех компонентов.
        // Их количество в списке может увеличиваться по мере работы цикла.
        // Список может содержать дубли.

        updateCount = 0;

        var i = 0;
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
                    updateCount ++;
                }
                else {
                    Browser.console.error("Компонент " + updateItems[i].toString() + " достиг лимита количества обновлений в одном цикле рендера (frame=" + frame + ") и будет пропущен, проверьте свойство: pui.Theme.updateMax", updateItems[i]);
                }
            }

            updateItems[i++] = null;
        }

        updateLen = 0;
        frame ++;

        if (Utils.noeq(onUpdateEnd, null))
            onUpdateEnd(this);
    }

    /**
     * Добавить компонент для обновления в текущем цикле рендера.
     * Метод используется внутренней реализацией для обновления компонентов.
     * 
     * @param component Компонент.
     */
    @:allow(pui.Component) 
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
        application.renderer.off(Event.POST_RENDER, onUpdateUI);

        styles = null;
        application = null;
        updateItems = null;
        onUpdateStart = null;
        onUpdateEnd = null;
        updateLen = 0;
        updateCount = 0;
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