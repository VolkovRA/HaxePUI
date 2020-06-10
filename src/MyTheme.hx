package;

import pui.*;
import pui.ui.*;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;
import pixi.core.text.TextStyle;

/**
 * Пример пользовательской темы оформления.
 */
class MyTheme extends Theme
{
    public function new(app:Application) {
        super(app);

        addStyle(Label.TYPE, "orange", setLabelOrange);
        addStyle(Label.TYPE, "pink", setLabelPink);
        addStyle(Label.TYPE, "h1", setLabelH1);
    }



    /////////////////////////
    //   ТЕКСТОВЫЕ СТИЛИ   //
    /////////////////////////

    private var textStyleOrange = new TextStyle({
        fontSize: 40,
        fill: 0xf68712,
        fontFamily: "Verdana",
        fontStyle: "bold",
        dropShadow: true,
        dropShadowColor: 0xf1471d,
        dropShadowAlpha: 1,
        dropShadowAngle: Utils.degToRad(90),
        dropShadowDistance: 1,
        dropShadowBlur: 0
    });
    private var textStylePink = new TextStyle({
        fontSize: 30,
        fill: 0xea1e63,
        fontFamily: "Verdana",
        fontStyle: "italic",
    });
    private var textStyleH1 = new TextStyle({
        fontSize: 40,
        fill: 0xffffff,
        fontFamily: "Verdana",
        fontStyle: "bold",
    });



    ////////////////////
    //   СТИЛИЗАЦИЯ   //
    ////////////////////

    private function setLabelOrange(label:Label):Void {
        label.skinText = new Text(label.text);
        label.skinText.style = textStyleOrange;
    }
    private function setLabelPink(label:Label):Void {
        label.skinText = new Text(label.text);
        label.skinText.style = textStylePink;
    }
    private function setLabelH1(label:Label):Void {
        label.skinText = new Text(label.text);
        label.skinText.style = textStyleH1;
    }
}