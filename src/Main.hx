package;

import pui.Label;
import pui.Theme;
import js.Browser;
import pixi.core.Application;

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
        title.style = "title";
        title.text = "PUI: PixiJS UI components";
        title.x = 5;
        title.y = 5;
        title.autosize = true;
        title.debug = true;
        app.stage.addChild(title);
    }

    static private function onUpdateUI(theme:GreenTheme):Void {
        if (theme.updateCount > 0)
            trace("Components updated: " + theme.updateCount);
    }
}