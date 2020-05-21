package;

import pui.*;
import pixi.core.Application;
import pixi.core.graphics.Graphics;
import pixi.core.text.Text;
import pixi.core.text.TextStyle;

/**
 * Пример создания темы оформления UI.
 */
class GreenTheme extends Theme
{
    public function new(app:Application) {
        super(app);

        addStyle(Label.TYPE, "title", setLabelTitle);
    }



    /////////////////////////
    //   ТЕКСТОВЫЕ СТИЛИ   //
    /////////////////////////

    // Тёмная, текстовая метка на фоне дерева.
    private var tsLabelTitle = new TextStyle({
        fontSize: 22.5,
        fill: 0x7d3219,
        fontFamily: "Verdana",
        wordWrap: true,
        dropShadow: true,
        dropShadowColor: 0xfdc08e,
        dropShadowAlpha: 0.26,
        dropShadowAngle: Utils.degToRad(90),
        dropShadowDistance: 1,
        dropShadowBlur: 0
    });

    ////////////////////
    //   СТИЛИЗАЦИЯ   //
    ////////////////////

    private function setLabelTitle(label:Label):Void {
        label.skinText = new Text(label.text);
        //label.debug = true;
        //label.skinText.style = tsLabelTitle;
    }
}