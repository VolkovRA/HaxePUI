package;

import pui.*;
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
            width: 550,
            height: 400,
            backgroundColor: 0x101010,
        });
        app.start();
        Browser.document.getElementsByTagName('body')[0].appendChild(app.view);

        // Create theme:
        Theme.current = new MyTheme(app);
        Theme.current.onUpdateEnd = onUpdateUI;

        // Create UI:
        var title:Label = new Label();
        title.text = "PUI: PixiJS UI components";
        title.debug = true;
        title.x = 5;
        title.y = 5;
        title.autosize = false;
        title.enabled = false;
        title.w = 500;
        title.h = 100;
        //title.padding = { top:-6, left:10, right:50, bottom: -10};
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
        bt.mouseInput = null;

        var sch = new ScrollBar();
        sch.x = 5;
        sch.y = 170;
        sch.min = -20;
        sch.max = 80;
        sch.step = 2;
        sch.orientation = Orientation.HORIZONTAL;
        sch.pointMode = true;
        sch.on(UIEvent.CHANGE, function(sch, value){ trace(sch.value); });
        //sch.debug = true;
        app.stage.addChild(sch);

        var sch2 = new ScrollBar();
        sch2.x = 5;
        sch2.y = 200;
        sch2.min = -20;
        sch2.max = 80;
        sch2.step = 2;
        sch2.orientation = Orientation.VERTICAL;
        sch2.on(UIEvent.CHANGE, function(sch, value){ trace(sch2.value); });
        //sch2.debug = true;
        app.stage.addChild(sch2);

        //var list = new List();
    }

    static private function onUpdateUI(theme:MyTheme):Void {
        if (theme.updateCount > 0)
            trace("Components updated: " + theme.updateCount);
    }
}