package;

import pixi.core.display.Container;
import pui.*;
import pui.ui.*;
import pui.geom.*;
import pui.events.*;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import js.Browser;

/**
 * Пример использования.
 */
class Main
{
    static private var NAMES = [        "Liam", "Emma", "Noah", "Olivia", "Mason", "Ava", "Ethan", "Sophia", "Logan",
                                        "Isabella", "Lucas", "Mia", "Jackson", "Charlotte", "Aiden", "Amelia",
                                        "Oliver", "Emily", "Jacob", "Madison", "Elijah", "Harper", "Alexander",
                                        "Abigail", "James", "Avery", "Benjamin", "Lily", "Jack", "Ella", "Luke",
                                        "Chloe", "William", "Evelyn", "Michael", "Sofia", "Owen", "Aria", "Daniel",
                                        "Ellie", "Carter", "Aubrey", "Gabriel", "Scarlett", "Henry", "Zoey", "Matthew",
                                        "Hannah", "Wyatt", "Audrey", "Caleb", "Grace", "Jayden", "Addison", "Nathan",
                                        "Zoe", "Ryan", "Elizabeth", "Isaac", "Nora"
    ];
    static private var ATTRIBUTES = [   "Strong", "Weak", "Smart", "Tall", "Drunk", "Humpbacked", "Clever", "Rich",
                                        "Poor", "Stupid", "Beggar", "Shell-shocked", "Evil", "Kind", "Sick", "Impudent",
                                        "Generous", "Brilliant", "Wet", "Nuts", "Sticky", "Iron", "Wood", "Dirty",
                                        "Fragile", "Thick", "Fatty", "Thin", "Clean", "Red", "Blue", "Green", "Gray", "Dark"
    ];

    private static var app:Application;
    private static var title1:Label;
    private static var title2:Label;
    private static var title3:Label;
    private static var title4:Label;
    private static var buttonsTitle:Label;
    private static var button1:Button;
    private static var button2:Button;
    private static var button3:Button;
    private static var scrollbarsTitle:Label;
    private static var scroll1:ScrollBar;
    private static var scroll2:ScrollBar;
    private static var scroll3:ScrollBar;
    private static var scrollersTitle:Label;
    private static var scroller1:Scroller;
    private static var scroller2:Scroller;
    private static var listTitle:Label;
    private static var list1:List;
    private static var listTitle2:Label;
    private static var list2:List;
    private static var progressTitle:Label;
    private static var progress1:ProgressBar;
    private static var progress2:ProgressBar;
    private static var checkTitle:Label;
    private static var check1:CheckBox;
    private static var check2:CheckBox;
    private static var check3:CheckBox;

    /**
     * Точка входа.
     */
    public static function main() {

        // Запуск pixi:
        app = new Application({
            width: 1600,
            height: 600,
            backgroundColor: 0x111111,
        });
        app.start();
        app.view.style.userSelect = "none";
        Browser.document.getElementById('game').appendChild(app.view);

        // Создание темы:
        Theme.current = new MyTheme(app);
        Theme.current.showError = false;
        Theme.current.on(ThemeEvent.UPDATE_FINISH, onThemeUpdateFinish);

        // Шапка:
        title1 = new Label("Haxe");
        title1.style = "orange";
        title1.x = 20;
        title1.y = 10;
        app.stage.addChild(title1);

        title2 = new Label("PixiJS");
        title2.style = "pink";
        title2.x = 160;
        title2.y = 20;
        app.stage.addChild(title2);

        title3 = new Label("V5");
        title3.x = 245;
        title3.y = 40;
        app.stage.addChild(title3);

        title4 = new Label("UI");
        title4.style = "h1";
        title4.x = 280;
        title4.y = 10;
        title4.autosize = true;
        title4.debug = true;
        app.stage.addChild(title4);

        // Кнопки:
        buttonsTitle = new Label("Button");
        buttonsTitle.x = 20;
        buttonsTitle.y = 130;
        app.stage.addChild(buttonsTitle);

        button1 = new Button();
        button1.text = "Button";
        button1.x = buttonsTitle.x;
        button1.y = buttonsTitle.y + 40;
        app.stage.addChild(button1);

        var ico:Graphics = new Graphics();
        ico.beginFill(0xffff00, 0.8);
        ico.drawCircle(5, 5, 5);
        button2 = new Button();
        button2.ico = ico;
        button2.icoGap = 5;
        button2.text = "With ico";
        button2.x = button1.x;
        button2.y = button1.y + 50;
        button2.paddingPress = { left:0, top:2, right:0, bottom:0 };
        app.stage.addChild(button2);

        ico = new Graphics();
        ico.beginFill(0x550000);
        ico.drawCircle(15, 15, 15);
        var ico2 = new Graphics();
        ico2.beginFill(0xFF0000);
        ico2.drawCircle(15, 15, 15);
        var ico3 = new Graphics();
        ico3.beginFill(0xFF0000);
        ico3.drawCircle(15, 15, 15);
        button3 = new Button();
        button3.ico = ico;
        button3.icoHover = ico2;
        button3.icoPress = ico3;
        button3.x = button2.x;
        button3.y = button2.y + 50;
        button3.paddingPress = { left:0, top:2, right:0, bottom:0 };
        app.stage.addChild(button3);

        // Скроллбары:
        scrollbarsTitle = new Label("ScrollBar");
        scrollbarsTitle.x = 200;
        scrollbarsTitle.y = 130;
        app.stage.addChild(scrollbarsTitle);

        scroll1 = new ScrollBar();
        scroll1.x = scrollbarsTitle.x;
        scroll1.y = scrollbarsTitle.y + 40;
        app.stage.addChild(scroll1);

        scroll2 = new ScrollBar();
        scroll2.x = scroll1.x;
        scroll2.y = scroll1.y + 30;
        scroll2.pointMode = true;
        app.stage.addChild(scroll2);

        scroll3 = new ScrollBar();
        scroll3.orientation = Orientation.VERTICAL;
        scroll3.x = scroll2.x;
        scroll3.y = scroll2.y + 30;
        app.stage.addChild(scroll3);

        // Скроллера
        scrollersTitle = new Label("Scroller");
        scrollersTitle.x = 400;
        scrollersTitle.y = 130;
        app.stage.addChild(scrollersTitle);

        scroller1 = new Scroller();
        scroller1.x = scrollersTitle.x;
        scroller1.y = scrollersTitle.y + 40;
        scroller1.w = 400;
        scroller1.h = 200;
        scroller1.drag = { allowX:true, allowY:true, inertia:{ allowX:true, allowY:true }};
        scroller1.outOfBounds = { allowX:true, allowY:true };
        scroller1.velocity = { allowX:true, allowY:true, speed:new Vec2(-300, -50) };
        addCircles(scroller1.content);
        app.stage.addChild(scroller1);

        scroller2 = new Scroller();
        scroller2.drag = scroller1.drag;
        scroller2.outOfBounds = scroller1.outOfBounds;
        scroller2.velocity = scroller1.velocity;
        scroller2.x = 900;
        addBox(scroller2.content);
        scroller1.content.addChild(scroller2);
        
        // Список:
        listTitle = new Label("List of 1000000 items");
        listTitle.x = 860;
        listTitle.y = 130;
        listTitle.w = 200;
        app.stage.addChild(listTitle);

        list1 = new List(ListItemLabel);
        list1.x = listTitle.x;
        list1.y = listTitle.y + 40;
        list1.w = 300;
        list1.h = 400;
        list1.viewsSize = 30;
        list1.viewsGap = 2;
        list1.orientation = Orientation.VERTICAL;
        list1.overflowX = Overflow.HIDDEN;
        list1.overflowY = Overflow.AUTO;
        rndNames(list1, 1000000);
        app.stage.addChild(list1);

        // Список динамический:
        listTitle2 = new Label("List with dynamic size items");
        listTitle2.x = 1210;
        listTitle2.y = 130;
        listTitle2.w = 200;
        app.stage.addChild(listTitle2);

        list2 = new List(CustomListItem);
        list2.x = listTitle2.x;
        list2.y = listTitle2.y + 40;
        list2.w = 300;
        list2.h = 400;
        list2.viewsSize = 0;
        list2.viewsGap = 2;
        list2.orientation = Orientation.VERTICAL;
        list2.overflowX = Overflow.HIDDEN;
        list2.overflowY = Overflow.AUTO;
        rndNames(list2, 50);
        app.stage.addChild(list2);

        // Прогрессбар:
        progressTitle = new Label("ProgressBar");
        progressTitle.x = 20;
        progressTitle.y = 450;
        app.stage.addChild(progressTitle);

        progress1 = new ProgressBar();
        progress1.x = progressTitle.x;
        progress1.y = progressTitle.y + 30;
        app.stage.addChild(progress1);

        progress2 = new ProgressBar();
        progress2.x = progress1.x;
        progress2.y = progress1.y + 30;
        progress2.orientation = Orientation.VERTICAL;
        progress2.h = 60;
        app.stage.addChild(progress2);

        // Чекбокс:
        checkTitle = new Label("CheckBox");
        checkTitle.x = 200;
        checkTitle.y = 450;
        app.stage.addChild(checkTitle);

        check1 = new CheckBox();
        check1.x = checkTitle.x;
        check1.y = checkTitle.y + 30;
        check1.value = false;
        app.stage.addChild(check1);

        check2 = new CheckBox();
        check2.x = check1.x;
        check2.y = check1.y + 34;
        check2.value = true;
        app.stage.addChild(check2);

        check3 = new CheckBox();
        check3.x = check2.x;
        check3.y = check2.y + 34;
        check3.value = null;
        app.stage.addChild(check3);
    }

    static private function onThemeUpdateFinish(e:ThemeEvent):Void {
        if (progress1.value == progress1.max)
            progress1.value = progress1.min;
        else
            progress1.value += 0.03;

        if (progress2.value == progress2.max)
            progress2.value = progress2.min;
        else
            progress2.value += 0.005;

        //if (e.updates > 0)
        //    trace("UI Updates: " + e.updates + ", total components: " + (Component.nextID-1));
    }

    static private function addCircles(container:Container):Void {
        var i = 100;
        while (i-- > 0) {
            var s = new Graphics();
            
            s.beginFill(getRndColor(), Math.random() * 0.5 + 0.5);
            s.drawCircle(0, 0, Math.random() * 10 + 5);
            s.x = Math.random() * 800;
            s.y = Math.random() * 200;
            container.addChild(s);
        }
    }

    static private function addBox(container:Container):Void {
        var g = new Graphics();
        var x = -100;
        var y = -100;
        var w = 800;
        var h = 600;

        g.beginFill(0xff0000);
        g.drawRect(x, y, w, h);
        g.beginFill(0xffff00);
        g.drawRect(x, y, 5, 5);
        g.drawRect(x + w-5, y, 5, 5);
        g.drawRect(x, y + h-5, 5, 5);
        g.drawRect(x + w-5, y + h-5, 5, 5);

        container.addChild(g);
    }
    
    static public function getRndColor():Int {
        var r = Math.floor(Math.random() * 0xff) << 16;
        var g = Math.floor(Math.random() * 0xff) << 8;
        var b = Math.floor(Math.random() * 0xff);

        return r + g + b;
    }

    static public function rndNames(list:List, num:Int):Void {
        var i = 0;
        var len1 = NAMES.length;
        var len2 = ATTRIBUTES.length;
        while(i < num) {
            list.push(++i + ". " + NAMES[Math.floor(Math.random()*len1)] + ' ' + ATTRIBUTES[Math.floor(Math.random()*len2)]);
        }
    }
}