package pui.ui;

import js.Syntax;
import pui.ui.Component;
import pui.ext.TextStyleMeasure;
import pixi.core.display.Container;
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
 * @event ComponentEvent.UPDATED    Компонент обновился. (Перерисовался)
 * @event WheelEvent.WHEEL          Промотка колёсиком мыши. Это событие необходимо включить: `Component.inputWheel`.
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
        super();
        
        this.componentType = TYPE;
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
    public var text(default, set):String = "";
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
     * Текстура текста.
     * 
     * Позволяет задать фоновое изображение под текстом.
     * При этом текст используется в качестве маски для текстуры.
     * 
     * - Это свойство работает только для векторного текста. (`skinText`)
     * - Текстура растягивается на ширину и высоту компонента.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления слоёв.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null`.
     */
    public var texture(default, set):Container = null;
    function set_texture(value:Container):Container {
        if (Utils.eq(value, texture))
            return value;

        if (texture != null) {
            texture.mask = null;
            Utils.hide(this, texture);
        }
        
        texture = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Текстура текста в выключенном состоянии.
     * 
     * Позволяет задать фоновое изображение под текстом.
     * При этом текст используется в качестве маски для текстуры.
     * 
     * - Это свойство работает только для векторного текста. (`skinText`)
     * - Текстура растягивается на ширину и высоту компонента.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     * - `Component.UPDATE_LAYERS` - Для обновления слоёв.
     * - `Component.UPDATE_SIZE` - Для повторного масштабирования.
     * 
     * По умолчанию: `null`.
     */
    public var textureDisable(default, set):Container = null;
    function set_textureDisable(value:Container):Container {
        if (Utils.eq(value, textureDisable))
            return value;

        if (textureDisable != null) {
            textureDisable.mask = null;
            Utils.hide(this, textureDisable);
        }
        
        textureDisable = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
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
        Utils.destroySkin(texture, options);
        Utils.destroySkin(skinText, options);
        Utils.destroySkin(skinBitmapText, options);
        Utils.delete(text);

        super.destroy(options);
    }

    /**
     * Получить строковое представление компонента.
     * @return Возвращает строковое представление компонента.
     */
    @:keep
    override public function toString():String {
        return Syntax.code( '"[" + {0}.componentType + {0}.componentID + " style=\\"" + {0}.style + "\\" text=\\"" + ({0}.text.length>50?({0}.text.substring(0,50)+"..."):{0}.text) +  "\\"]"', this);
    }



    /////////////////////////////////
    //   ПОЗИЦИАНИРОВАНИЕ И СЛОИ   //
    /////////////////////////////////

    /**
     * Базовое обновление списка отображения компонента `Label`.
     */
    static public var updateLayersDefault:LayersUpdater<Label> = function(c) {
        var bg:Container = c.skinBg; // <-- Базовый скин, если не указано иное
        var tu:Container = c.texture;
        var tx:Text = c.skinText;
        var txb:BitmapText = c.skinBitmapText;
        var skins:Array<Container> = [ // Все скины, учавствующие в отображении. (В порядке отображения)
            c.skinBg,
            c.skinBgDisable,

            c.skinText,
            c.skinTextDisable,
            c.texture,
            c.textureDisable,

            c.skinBitmapText,
            c.skinBitmapTextDisable
        ];

        // Конкретные скины:
        if (!c.enabled) {
            if (c.skinBgDisable != null)            bg = c.skinBgDisable;
            if (c.textureDisable != null)           tu = c.textureDisable;
            if (c.skinTextDisable != null)          tx = c.skinTextDisable;
            if (c.skinBitmapTextDisable != null)    txb = c.skinBitmapTextDisable;
        }
        
        // Режим маски:
        if (tu != null)
            tu.mask = tx;

        // Отображение:
        var i = 0;
        var len = skins.length;
        while (i < len) {
            var skin = skins[i++];
            if (skin == null)
                continue;
            
            if (Utils.eq(skin,bg) || Utils.eq(skin,tu) || Utils.eq(skin,tx) || Utils.eq(skin,txb)) {
                c.addChild(skin);
            }
            else {
                if (Utils.eq(skin.parent,c))
                    c.removeChild(skin);
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
            if (label.padding.top != null)      pt = label.padding.top;
            if (label.padding.left != null)     pl = label.padding.left;
            if (label.padding.left != null)     pr = label.padding.left;
            if (label.padding.bottom != null)   pb = label.padding.bottom;
        }

        var pt2 = pt;
        var pl2 = pl;
        var pr2 = pr;
        var pb2 = pb;
        if (Utils.noeq(label.paddingDisable, null)) {
            if (label.paddingDisable.top != null)      pt2 = label.paddingDisable.top;
            if (label.paddingDisable.left != null)     pl2 = label.paddingDisable.left;
            if (label.paddingDisable.left != null)     pr2 = label.paddingDisable.left;
            if (label.paddingDisable.bottom != null)   pb2 = label.paddingDisable.bottom;
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
                    var style:TextStyleMeasure = untyped label.skinText.style;
                    Utils.set(label.w, Math.round(mst.maxLineWidth + Math.max(0, pl) + Math.max(0, pr) + (style.measureWidth==null?0:style.measureWidth)));
                    Utils.set(label.h, Math.round(mst.lines.length * mst.lineHeight + Math.max(0, pt) + Math.max(0, pb) + (style.measureHeight==null?0:style.measureHeight)));
                }
                else if (Utils.noeq(label.skinBitmapText, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapText.width + Math.max(0, pl) + Math.max(0, pr)));
                    Utils.set(label.h, Math.round(label.skinBitmapText.height + Math.max(0, pt) + Math.max(0, pb)));
                }
                else {
                    Utils.set(label.w, Math.max(0, pl) + Math.max(0, pr));
                    Utils.set(label.h, Math.max(0, pt) + Math.max(0, pb));
                }
            }
            else {
                if (Utils.noeq(label.skinTextDisable, null)) {
                    var style:TextStyleMeasure = untyped label.skinTextDisable.style;
                    Utils.set(label.w, Math.round(mstd.maxLineWidth + Math.max(0, pl2) + Math.max(0, pr2) + (style.measureWidth==null?0:style.measureWidth)));
                    Utils.set(label.h, Math.round(mstd.lines.length * mstd.lineHeight + Math.max(0, pt2) + Math.max(0, pb2) + (style.measureHeight==null?0:style.measureHeight)));
                }
                else if (Utils.noeq(label.skinBitmapTextDisable, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapTextDisable.width + Math.max(0, pl2) + Math.max(0, pr2)));
                    Utils.set(label.h, Math.round(label.skinBitmapTextDisable.height + Math.max(0, pt2) + Math.max(0, pb2)));
                }
                else if (Utils.noeq(label.skinText, null)) {
                    var style:TextStyleMeasure = untyped label.skinText.style;
                    Utils.set(label.w, Math.round(mst.maxLineWidth + Math.max(0, pl2) + Math.max(0, pr2) + (style.measureWidth==null?0:style.measureWidth)));
                    Utils.set(label.h, Math.round(mst.lines.length * mst.lineHeight + Math.max(0, pt2) + Math.max(0, pb2) + (style.measureHeight==null?0:style.measureHeight)));
                }
                else if (Utils.noeq(label.skinBitmapText, null)) {
                    Utils.set(label.w, Math.round(label.skinBitmapText.width + Math.max(0, pl2) + Math.max(0, pr2)));
                    Utils.set(label.h, Math.round(label.skinBitmapText.height + Math.max(0, pt2) + Math.max(0, pb2)));
                }
                else {
                    Utils.set(label.w, Math.max(0, pl2) + Math.max(0, pr2));
                    Utils.set(label.h, Math.max(0, pt2) + Math.max(0, pb2));
                }
            }
        }

        // Позицианирование:
        if (Utils.noeq(label.skinText, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinText.x = Math.round(pl + label.w - mst.maxLineWidth - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinText.x = Math.round(pl + (label.w - mst.maxLineWidth - pl - pr) / 2);
                else                                            label.skinText.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinText.y = Math.round(pt + label.h - mst.lines.length * mst.lineHeight - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinText.y = Math.round(pt + (label.h - mst.lines.length * mst.lineHeight - pt - pb) / 2);
                else                                            label.skinText.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinText.x = Math.round(pl2 + label.w - mst.maxLineWidth - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinText.x = Math.round(pl2 + (label.w - mst.maxLineWidth - pl2 - pr2) / 2);
                else                                            label.skinText.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinText.y = Math.round(pt2 + label.h - mst.lines.length * mst.lineHeight - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinText.y = Math.round(pt2 + (label.h - mst.lines.length * mst.lineHeight - pt2 - pb2) / 2);
                else                                            label.skinText.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinTextDisable, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinTextDisable.x = Math.round(pl + label.w - mstd.maxLineWidth - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinTextDisable.x = Math.round(pl + (label.w - mstd.maxLineWidth - pl - pr) / 2);
                else                                            label.skinTextDisable.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinTextDisable.y = Math.round(pt + label.h - mstd.lines.length * mstd.lineHeight - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinTextDisable.y = Math.round(pt + (label.h - mstd.lines.length * mstd.lineHeight - pt - pb) / 2);
                else                                            label.skinTextDisable.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinTextDisable.x = Math.round(pl2 + label.w - mstd.maxLineWidth - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinTextDisable.x = Math.round(pl2 + (label.w - mstd.maxLineWidth - pl2 - pr2) / 2);
                else                                            label.skinTextDisable.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinTextDisable.y = Math.round(pt2 + label.h - mstd.lines.length * mstd.lineHeight - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinTextDisable.y = Math.round(pt2 + (label.h - mstd.lines.length * mstd.lineHeight - pt2 - pb2) / 2);
                else                                            label.skinTextDisable.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinBitmapText, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapText.x = Math.round(pl + label.w - label.skinBitmapText.width - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapText.x = Math.round(pl + (label.w - label.skinBitmapText.width - pl - pr) / 2);
                else                                            label.skinBitmapText.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapText.y = Math.round(pt + label.h - label.skinBitmapText.height - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapText.y = Math.round(pt + (label.h - label.skinBitmapText.height - pt - pb) / 2);
                else                                            label.skinBitmapText.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapText.x = Math.round(pl2 + label.w - label.skinBitmapText.width - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapText.x = Math.round(pl2 + (label.w - label.skinBitmapText.width - pl2 - pr2) / 2);
                else                                            label.skinBitmapText.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapText.y = Math.round(pt2 + label.h - label.skinBitmapText.height - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapText.y = Math.round(pt2 + (label.h - label.skinBitmapText.height - pt2 - pb2) / 2);
                else                                            label.skinBitmapText.y = Math.round(pt2);
            }
        }
        if (Utils.noeq(label.skinBitmapTextDisable, null)) {
            if (label.enabled) {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapTextDisable.x = Math.round(pl + label.w - label.skinBitmapTextDisable.width - pr);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapTextDisable.x = Math.round(pl + (label.w - label.skinBitmapTextDisable.width - pl - pr) / 2);
                else                                            label.skinBitmapTextDisable.x = Math.round(pl);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapTextDisable.y = Math.round(pt + label.h - label.skinBitmapTextDisable.height - pb);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapTextDisable.y = Math.round(pt + (label.h - label.skinBitmapTextDisable.height - pt - pb) / 2);
                else                                            label.skinBitmapTextDisable.y = Math.round(pt);
            }
            else {
                if (Utils.eq(label.alignX, AlignX.RIGHT))       label.skinBitmapTextDisable.x = Math.round(pl2 + label.w - label.skinBitmapTextDisable.width - pr2);
                else if (Utils.eq(label.alignX, AlignX.CENTER)) label.skinBitmapTextDisable.x = Math.round(pl2 + (label.w - label.skinBitmapTextDisable.width - pl2 - pr2) / 2);
                else                                            label.skinBitmapTextDisable.x = Math.round(pl2);
                
                if (Utils.eq(label.alignY, AlignY.BOTTOM))      label.skinBitmapTextDisable.y = Math.round(pt2 + label.h - label.skinBitmapTextDisable.height - pb2);
                else if (Utils.eq(label.alignY, AlignY.CENTER)) label.skinBitmapTextDisable.y = Math.round(pt2 + (label.h - label.skinBitmapTextDisable.height - pt2 - pb2) / 2);
                else                                            label.skinBitmapTextDisable.y = Math.round(pt2);
            }
        }

        // Текстура и маска:
        var tu = label.texture;
        var tx = label.skinText;
        if (label.textureDisable != null && label.textureDisable.parent == label)
            tu = label.textureDisable;
        if (label.skinTextDisable != null && label.skinTextDisable.parent == label)
            tx = label.skinTextDisable;
        if (tu != null) {
            if (tx == null) {
                tu.x = 0;
                tu.y = 0;
            }
            else {
                tu.x = tx.x;
                tu.y = tx.y;
            }
            tu.width = label.w;
            tu.height = label.h;
        }

        // Фоны:
        Utils.size(label.skinBg, label.w, label.h);
        Utils.size(label.skinBgDisable, label.w, label.h);
    }
}