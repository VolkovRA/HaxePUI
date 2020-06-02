package pui;

import js.Syntax;
import pui.Component;
import pixi.core.display.DisplayObject;
import pixi.core.text.Text;
import pixi.core.text.TextMetrics;
import pixi.extras.BitmapText;
import haxe.extern.EitherType;

/**
 * Текстовая метка.
 * 
 * Абстрагирует отображаемый текст, позволяя выполнить реализацию как через обычный `Text`,
 * так и с использованием растрового шрифта: `BitmapText`.
 * 
 * *пс. На данный момент поддержка растрового шрифта не проверена полностью.*
 * 
 * События:
 *   * `UIEvent.UPDATE` - Текстовая метка обновилась: `Label->changes->Void`. (Передаёт старые изменения)
 *   * *А также все базовые события pixijs: https://pixijs.download/dev/docs/PIXI.Container.html*
 */
class Label extends Component
{
    /**
     * Тип компонента.
     */
    static public inline var TYPE:String = "Label";

    /**
     * Создать текстовую метку.
     * @param text Отображаемый текст.
     */
    public function new(text:String = "") {
        super(TYPE);
        
        this.text = text;

        Utils.set(this.updateLayers, Label.updateLayersDefault);
        Utils.set(this.updateSize, Label.updateSizeDefault);
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Отображаемый текст.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `""`. (Не может быть `null`)
     */
    public var text(default, set):String;
    function set_text(value:String):String {
        if (value == null) {
            if (Utils.eq(text, ""))
                return value;

            text = value;
            update(false, Component.UPDATE_SIZE);
            return value;
        }

        if (Utils.eq(value, text))
            return value;

        text = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Выравнивание текста по горизонтали.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `AlignX.LEFT`.
     */
    public var alignX(default, set):AlignX = AlignX.LEFT;
    function set_alignX(value:AlignX):AlignX {
        if (Utils.eq(value, alignX))
            return value;

        alignX = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Выравнивание текста по вертикали.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `AlignY.TOP`.
     */
    public var alignY(default, set):AlignY = AlignY.TOP;
    function set_alignY(value:AlignY):AlignY {
        if (Utils.eq(value, alignY))
            return value;

        alignY = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Автоматическое изменение размеров.
     * 
     * Если задано `true`, размеры `w` и `h` будут каждый раз **пересчитываться**,
     * в зависимости от размеров содержимого текста и заданных отступов: `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `false`.
     */
    public var autosize(default, set):Bool = false;
    function set_autosize(value:Bool):Bool {
        if (Utils.eq(value, autosize))
            return value;

        autosize = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ текста от краёв в выключенном состоянии. (px)
     * Если не задано, используется `padding`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `null`.
     */
    public var paddingDisable(default, set):Offset = null;
    function set_paddingDisable(value:Offset):Offset {
        if (Utils.eq(value, paddingDisable))
            return value;

        paddingDisable = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин текстового поля.
     * Текст в таком поле рендерится и **загружается заного** в GPU при каждом изменении!
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления/удаления текста в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
     * 
     * По умолчанию: `null`.
     */
    public var skinText(default, set):Text = null;
    function set_skinText(value:Text):Text {
        if (Utils.eq(value, skinText))
            return value;

        Utils.hide(this, skinText);

        skinText = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин текстового поля в выключенном состоянии. (`enabled=false`)
     * Текст в таком поле рендерится и **загружается заного** в GPU при каждом изменении!
     * 
      * Если не указан, используется: `skinText`.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для добавления/удаления текста в дисплей лист.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
     * 
     * По умолчанию: `null`.
     */
    public var skinTextDisable(default, set):Text = null;
    function set_skinTextDisable(value:Text):Text {
        if (Utils.eq(value, skinTextDisable))
            return value;

        Utils.hide(this, skinTextDisable);

        skinTextDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
      * Скин растрового, текстового поля.
      * Этот текст рендерится очень быстро из заранее подготовленных глифов.
      * 
      * При установке нового значения регистрируются изменения в компоненте:
      * - `Component.UPDATE_LAYERS` - Для добавления/удаления растрового текста в дисплей лист.
      * - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
      * 
      * По умолчанию: `null`.
      */
    public var skinBitmapText(default, set):BitmapText = null;
    function set_skinBitmapText(value:BitmapText):BitmapText {
        if (Utils.eq(value, skinBitmapText))
            return value;

        Utils.hide(this, skinBitmapText);

        skinBitmapText = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
      * Скин растрового, текстового поля в выключеном состоянии.
      * Этот текст рендерится очень быстро из заранее подготовленных глифов.
      * 
      * Если не указан, используется: `skinBitmapText`.
      * 
      * При установке нового значения регистрируются изменения в компоненте:
      * - `Component.UPDATE_LAYERS` - Для добавления/удаления растрового текста в дисплей лист.
      * - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
      * 
      * По умолчанию: `null`.
      */
    public var skinBitmapTextDisable(default, set):BitmapText = null;
    function set_skinBitmapTextDisable(value:BitmapText):BitmapText {
        if (Utils.eq(value, skinBitmapTextDisable))
            return value;

        Utils.hide(this, skinBitmapTextDisable);

        skinBitmapTextDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Задать стиль для всех текстовых скинов.
     * Задаёт свойство стиля для всех назначенных скинов текста.
     * @param param Имя стиля. Например: `"align"`.
     * @param value Значение. В зависимости от свойства, может быть Float, String или т.п.
     */
    public function setTextStyle(param:String, value:Dynamic):Void {
        if (Utils.noeq(skinText, null))             Syntax.code('{0}[{1}] = {2}', skinText.style, param, value);
        if (Utils.noeq(skinTextDisable, null))      Syntax.code('{0}[{1}] = {2}', skinTextDisable.style, param, value);
    }

	/**
     * Выгрузить текстовую метку.
	 */
    override function destroy(?options:EitherType<Bool, DestroyOptions>) {
        if (Utils.noeq(skinText, null)) {
            skinText.destroy();
            Utils.delete(skinText);
        }
        if (Utils.noeq(skinBitmapText, null)) {
            skinBitmapText.destroy();
            Utils.delete(skinBitmapText);
        }

        Utils.delete(text);

        super.destroy(options);
    }

    /**
     * Получить строковое представление компонента.
     * @return Возвращает строковое представление компонента.
     */
    @:keep
    override public function toString():String {
        return Syntax.code( '"[" + {0}.componentType + " style=\\"" + {0}.style + "\\" text=\\"" + ({0}.text.length>50?({0}.text.substring(0,50)+"..."):{0}.text) +  "\\"]"', this);
    }



    /////////////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ И СЛОИ   //
    /////////////////////////////////

    /**
     * Базовое обновление списка отображения компонента `Label`.
     */
    static public var updateLayersDefault:LayersUpdater<Label> = function(label) {
        if (label.enabled) {
            Utils.show(label, label.skinBg);
            Utils.hide(label, label.skinBgDisable);

            Utils.show(label, label.skinText);
            Utils.hide(label, label.skinTextDisable);

            Utils.show(label, label.skinBitmapText);
            Utils.hide(label, label.skinBitmapTextDisable);
        }
        else {
            if (Utils.eq(label.skinBgDisable, null)) {
                Utils.show(label, label.skinBg);
                //Utils.hide(component, component.skinBgDisable);
            }
            else {
                Utils.hide(label, label.skinBg);
                Utils.show(label, label.skinBgDisable);
            }

            if (Utils.eq(label.skinTextDisable, null)) {
                Utils.show(label, label.skinText);
                //Utils.hide(label, label.skinTextDisable);
            }
            else {
                Utils.hide(label, label.skinText);
                Utils.show(label, label.skinTextDisable);
            }

            if (Utils.eq(label.skinBitmapTextDisable, null)) {
                Utils.show(label, label.skinBitmapText);
                //Utils.hide(label, label.skinBitmapTextDisable);
            }
            else {
                Utils.hide(label, label.skinBitmapText);
                Utils.show(label, label.skinBitmapTextDisable);
            }
        }
    }

    /**
     * Базовое обновление размеров компонента `Label`.
     */
    static public var updateSizeDefault:SizeUpdater<Label> = function(label) {
        var pt:Float = 0;
        var pl:Float = 0;
        var pr:Float = 0;
        var pb:Float = 0;

        if (Utils.noeq(label.padding, null)) {
            pt = label.padding.top;
            pl = label.padding.left;
            pr = label.padding.right;
            pb = label.padding.bottom;
        }

        var pt2 = pt;
        var pl2 = pl;
        var pr2 = pr;
        var pb2 = pb;

        if (Utils.noeq(label.paddingDisable, null)) {
            pt2 = label.paddingDisable.top;
            pl2 = label.paddingDisable.left;
            pr2 = label.paddingDisable.right;
            pb2 = label.paddingDisable.bottom;
        }

        // Общие стили текста:
        label.setTextStyle("wordWrap", true);

        if (Utils.eq(label.alignX, AlignX.RIGHT))
            label.setTextStyle("align", "right");
        else if (Utils.eq(label.alignX, AlignX.CENTER))
            label.setTextStyle("align", "center");
        else
            label.setTextStyle("align", "left");
            
        // Обновление векторного текста:
        var mst:TextMetrics = null;
        var mstd:TextMetrics = null;
        if (Utils.noeq(label.skinText, null)) {
            label.skinText.style.wordWrapWidth = label.autosize?999999:Math.max(0, label.w - pl - pr);
            label.skinText.text = label.text;
            label.skinText.updateText(true);
            mst = TextMetrics.measureText(label.text, untyped label.skinText.style, label.skinText.style.wordWrap);
        }
        if (Utils.noeq(label.skinTextDisable, null)) {
            label.skinTextDisable.style.wordWrapWidth = label.autosize?999999:Math.max(0, label.w - pl2 - pr2);
            label.skinTextDisable.text = label.text;
            label.skinTextDisable.updateText(true);
            mstd = TextMetrics.measureText(label.text, untyped label.skinTextDisable.style, label.skinTextDisable.style.wordWrap);
        }

        // Обновление растрового текста:
        if (Utils.noeq(label.skinBitmapText, null)) {
            label.skinBitmapText.text = label.text;
        }
        if (Utils.noeq(label.skinBitmapTextDisable, null)) {
            label.skinBitmapTextDisable.text = label.text;
        }

        // Авторазмеры:
        if (label.autosize) {
            // Определяем новые размеры компонента: (Зависит от состояния)
            if (label.enabled) {
                if (Utils.noeq(label.skinText, null)) {
                    Utils.set(label.w, Math.round(mst.maxLineWidth + pl + pr));
                    Utils.set(label.h, Math.round(mst.lines.length * mst.lineHeight + pt + pb));
                }
                else if (Utils.noeq(label.skinBitmapText, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapText.width + pl + pr));
                    Utils.set(label.h, Math.round(label.skinBitmapText.height + pt + pb));
                }
                else {
                    Utils.set(label.w, pl + pr);
                    Utils.set(label.h, pt + pb);
                }
            }
            else {
                if (Utils.noeq(label.skinTextDisable, null)) {
                    Utils.set(label.w, Math.round(mstd.maxLineWidth + pl2 + pr2));
                    Utils.set(label.h, Math.round(mstd.lines.length * mstd.lineHeight + pt2 + pb2));
                }
                else if (Utils.noeq(label.skinBitmapTextDisable, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapTextDisable.width + pl2 + pr2));
                    Utils.set(label.h, Math.round(label.skinBitmapTextDisable.height + pt2 + pb2));
                }
                else if (Utils.noeq(label.skinText, null)) {
                    Utils.set(label.w, Math.round(mst.maxLineWidth + pl2 + pr2));
                    Utils.set(label.h, Math.round(mst.lines.length * mst.lineHeight + pt2 + pb2));
                }
                else if (Utils.noeq(label.skinBitmapText, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapText.width + pl2 + pr2));
                    Utils.set(label.h, Math.round(label.skinBitmapText.height + pt2 + pb2));
                }
                else {
                    Utils.set(label.w, pl2 + pr2);
                    Utils.set(label.h, pt2 + pb2);
                }
            }
        }

        // Позицианирование:
        if (Utils.noeq(label.skinText, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinText.x = Math.round(label.w - mst.maxLineWidth - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinText.x = Math.round((label.w - mst.maxLineWidth) / 2);
                else                                            label.skinText.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinText.y = Math.round(label.h - mst.lines.length * mst.lineHeight - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinText.y = Math.round((label.h - mst.lines.length * mst.lineHeight) / 2);
                else                                            label.skinText.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinText.x = Math.round(label.w - mst.maxLineWidth - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinText.x = Math.round((label.w - mst.maxLineWidth) / 2);
                else                                            label.skinText.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinText.y = Math.round(label.h - mst.lines.length * mst.lineHeight - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinText.y = Math.round((label.h - mst.lines.length * mst.lineHeight) / 2);
                else                                            label.skinText.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinTextDisable, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinTextDisable.x = Math.round(label.w - mstd.maxLineWidth - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinTextDisable.x = Math.round((label.w - mstd.maxLineWidth) / 2);
                else                                            label.skinTextDisable.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinTextDisable.y = Math.round(label.h - mstd.lines.length * mstd.lineHeight - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinTextDisable.y = Math.round((label.h - mstd.lines.length * mstd.lineHeight) / 2);
                else                                            label.skinTextDisable.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinTextDisable.x = Math.round(label.w - mstd.maxLineWidth - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinTextDisable.x = Math.round((label.w - mstd.maxLineWidth) / 2);
                else                                            label.skinTextDisable.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinTextDisable.y = Math.round(label.h - mstd.lines.length * mstd.lineHeight - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinTextDisable.y = Math.round((label.h - mstd.lines.length * mstd.lineHeight) / 2);
                else                                            label.skinTextDisable.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinBitmapText, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapText.x = Math.round(label.w - label.skinBitmapText.width - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapText.x = Math.round((label.w - label.skinBitmapText.width) / 2);
                else                                            label.skinBitmapText.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapText.y = Math.round(label.h - label.skinBitmapText.height - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapText.y = Math.round((label.h - label.skinBitmapText.height) / 2);
                else                                            label.skinBitmapText.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapText.x = Math.round(label.w - label.skinBitmapText.width - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapText.x = Math.round((label.w - label.skinBitmapText.width) / 2);
                else                                            label.skinBitmapText.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapText.y = Math.round(label.h - label.skinBitmapText.height - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapText.y = Math.round((label.h - label.skinBitmapText.height) / 2);
                else                                            label.skinBitmapText.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinBitmapTextDisable, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapTextDisable.x = Math.round(label.w - label.skinBitmapTextDisable.width - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapTextDisable.x = Math.round((label.w - label.skinBitmapTextDisable.width) / 2);
                else                                            label.skinBitmapTextDisable.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapTextDisable.y = Math.round(label.h - label.skinBitmapTextDisable.height - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapTextDisable.y = Math.round((label.h - label.skinBitmapTextDisable.height) / 2);
                else                                            label.skinBitmapTextDisable.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapTextDisable.x = Math.round(label.w - label.skinBitmapTextDisable.width - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapTextDisable.x = Math.round((label.w - label.skinBitmapTextDisable.width) / 2);
                else                                            label.skinBitmapTextDisable.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapTextDisable.y = Math.round(label.h - label.skinBitmapTextDisable.height - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapTextDisable.y = Math.round((label.h - label.skinBitmapTextDisable.height) / 2);
                else                                            label.skinBitmapTextDisable.y = Math.round(pt2);
            }
        }

        // Фоны:
        Utils.size(label.skinBg, label.w, label.h);
        Utils.size(label.skinBgDisable, label.w, label.h);
    }
}