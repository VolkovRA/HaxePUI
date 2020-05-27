package;

import pui.*;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import js.Browser;

class Main
{
    public static var app:Application;

    public static function main() {

        // Start pixi:
        app = new Application({
            width: 550,
            height: 400,
            backgroundColor: 0xEEEEEE,
        });
        app.start();
        Browser.document.getElementsByTagName('body')[0].appendChild(app.view);

        // Create theme:
        Theme.current = new GreenTheme(app);
        Theme.current.onUpdateEnd = onUpdateUI;

        // Create UI:
        var title:Label = new Label();
        title.text = "PUI: PixiJS\nUIcomponents";
        title.debug = true;
        title.x = 5;
        title.y = 5;
        title.autosize = false;
        title.enabled = false;
        title.w = 500;
        title.h = 100;
        //title.padding = { top:-6, left:10, right:50, bottom: -10};
        title.alignX = AlignX.RIGHT;
        title.alignY = AlignY.BOTTOM;
        app.stage.addChild(title);

        var ico:Graphics = new Graphics();
        ico.beginFill(0xffff00, 0.8);
        ico.drawCircle(5, 5, 5);

        var bt:Button = new Button();
        bt.text = "Button";
        
        //bt.debug = true;
        bt.x = 5;
        bt.y = 120;
        bt.ico = ico;
        bt.icoGap = 5;
        bt.paddingHover = {top: -1, left:0, right:0, bottom:1 };
        bt.paddingPress = {top: 1, left:0, right:0, bottom:0 };
        //bt.enabled = false;
        app.stage.addChild(bt);
        bt.mouseInput = null;
    }

    static private function onUpdateUI(theme:GreenTheme):Void {
        if (theme.updateCount > 0)
            trace("Components updated: " + theme.updateCount);
    }
}