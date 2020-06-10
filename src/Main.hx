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
    public static var app:Application;

    /**
     * Точка входа.
     */
    public static function main() {

        // Start pixi:
        app = new Application({
            width: 800,
            height: 500,
            backgroundColor: 0x101010,
        });
        app.start();
        Browser.document.getElementsByTagName('body')[0].appendChild(app.view);

        // Create theme:
        Theme.current = new MyTheme(app);
        Theme.current.on(ThemeEvent.UPDATE_FINISH, onThemeUpdateFinish);

        // Create UI:
        var title:Label = new Label();
        title.text = "PUI: PixiJS UI components";
        title.debug = true;
        title.autosize = false;
        title.enabled = false;
        //title.update(true);
        title.w = 450;
        title.h = 50;
        title.padding = { top:6, left:6, right:6, bottom:6};
        title.margin = { top:10, left:10, right:10, bottom:10};
        title.x = 5 + title.margin.left;
        title.y = 5 + title.margin.top;
        title.alignX = AlignX.CENTER;
        title.alignY = AlignY.CENTER;
        app.stage.addChild(title);

        var ico:Graphics = new Graphics();
        ico.beginFill(0xffff00, 0.8);
        ico.drawCircle(5, 5, 5);

        var bt:Button = new Button();
        bt.text = "Button";
        
        //bt.debug = true;
        bt.x = 5;
        bt.y = 120;
        //bt.ico = ico;
        //bt.icoGap = 5;
        //bt.paddingHover = {top: -1, left:0, right:0, bottom:1 };
        bt.paddingPress = {top: 1, left:0, right:0, bottom:0 };
        //bt.enabled = false;
        app.stage.addChild(bt);
        bt.inputMouse = null;

        var sch = new ScrollBar();
        sch.x = 5;
        sch.y = 170;
        sch.min = -20;
        sch.max = 80;
        sch.step = 2;
        sch.orientation = Orientation.HORIZONTAL;
        sch.pointMode = true;
        //sch.debug = true;
        app.stage.addChild(sch);

        var sch2 = new ScrollBar();
        sch2.x = 5;
        sch2.y = 200;
        sch2.min = -20;
        sch2.max = 80;
        sch2.step = 2;
        sch2.orientation = Orientation.VERTICAL;
        //sch2.debug = true;
        app.stage.addChild(sch2);

        var sc = new Scroller();
        sc.x = 170;
        sc.y = 100;
        sc.w = 300;
        sc.h = 200;
        //sc.overflowX = Overflow.SCROLL;
        //sc.overflowY = Overflow.SCROLL;
        sc.velocity.speed.x = 300;
        sc.velocity.speed.y = 100;
        //sc.debug = true;
        addCircles(sc.content);
        //addBox(sc.content);
        app.stage.addChild(sc);

        var sc2 = new Scroller();
        sc2.w = 100;
        sc2.h = 100;
        //sc2.visible = false;
        //sc2.overflowX = Overflow.SCROLL;
        //sc2.overflowY = Overflow.SCROLL;
        //sc2.debug = true;
        addBox(sc2.content);
        sc.content.addChild(sc2);
    }

    static private function onThemeUpdateFinish(e:ThemeEvent):Void {
        if (e.updates > 0)
            trace("Components updated: " + e.updates);
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
}