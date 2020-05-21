package pui;

import js.Syntax;
import pui.Component;
import pixi.core.display.DisplayObject;
import pixi.extras.BitmapText;
import pixi.core.text.Text;
import haxe.extern.EitherType;

/**
 * Текстовая метка.
 * 
 * Абстрагирует отображаемый текст, позволяя выполнить реализацию как через обычный `Text`,
 * так и с использованием растрового шрифта: `BitmapText`.
 * 
 * *пс. На данный момент поддержка растрового шрифта не реализована но остаётся в планах.*
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
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `""`. (Не может быть `null`)
     */
    public var text(default, set):String;
    function set_text(value:String):String {
        if (Utils.eq(value, null)) {
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
     * Выравнивание текста.
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `TextAlign.LEFT`.
     */
    public var align(default, set):TextAlign = TextAlign.LEFT;
    function set_align(value:TextAlign):TextAlign {
        if (Utils.eq(value, align))
            return value;

        align = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Автоматическое изменение размеров.
     * 
     * Если задано `true`, размеры `w` и `h` будут каждый раз **пересчитываться**,
     * в зависимости от размеров содержимого текста и заданных отступов: `padding`.
     * 
     * *пс. Вы по прежнему ***можете*** контролировать ширину многостраничного текста
     * через его стили. (см.: pixi.core.text.DefaultStyle.wordWrapWidth)*
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
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
     * Отступ текста от левого края. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `0`.
     */
    public var paddingLeft(default, set):Float = 0;
    function set_paddingLeft(value:Float):Float {
        if (Utils.eq(value, paddingLeft))
            return value;

        paddingLeft = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ текста от правого края. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `0`.
     */
    public var paddingRight(default, set):Float = 0;
    function set_paddingRight(value:Float):Float {
        if (Utils.eq(value, paddingRight))
            return value;

        paddingRight = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ текста от верхнего края. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `0`.
     */
    public var paddingTop(default, set):Float = 0;
    function set_paddingTop(value:Float):Float {
        if (Utils.eq(value, paddingTop))
            return value;

        paddingTop = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Отступ текста от нижнего края. (px)
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования текстовой метки.
     * 
     * По умолчанию: `0`.
     */
    public var paddingBottom(default, set):Float = 0;
    function set_paddingBottom(value:Float):Float {
        if (Utils.eq(value, paddingBottom))
            return value;

        paddingBottom = value;
        update(false, Component.UPDATE_SIZE);
        return value;
    }

    /**
     * Скин текстового поля.
     * Текст в таком поле рендерится и **загружается заного** в GPU при каждом изменении!
     * 
     * При установке нового значения регистрируются изменения в компоненте:
     *   - `Component.UPDATE_LAYERS` - Для добавления/удаления текста в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
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
     *   - `Component.UPDATE_LAYERS` - Для добавления/удаления текста в дисплей лист.
     *   - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
     * 
     * По умолчанию: `null`.
     */
    public var skinTextDisabled(default, set):Text = null;
    function set_skinTextDisabled(value:Text):Text {
        if (Utils.eq(value, skinTextDisabled))
            return value;

        Utils.hide(this, skinTextDisabled);

        skinTextDisabled = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }

    /**
      * Скин растрового, текстового поля.
      * Этот текст рендерится очень быстро из заранее подготовленных глифов.
      * 
      * При установке нового значения регистрируются изменения в компоненте:
      *   - `Component.UPDATE_LAYERS` - Для добавления/удаления растрового текста в дисплей лист.
      *   - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
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
      *   - `Component.UPDATE_LAYERS` - Для добавления/удаления растрового текста в дисплей лист.
      *   - `Component.UPDATE_SIZE` - Для повторного масштабирования содержимого.
      * 
      * По умолчанию: `null`.
      */
    public var skinBitmapTextDisabled(default, set):BitmapText = null;
    function set_skinBitmapTextDisabled(value:BitmapText):BitmapText {
        if (Utils.eq(value, skinBitmapTextDisabled))
            return value;

        Utils.hide(this, skinBitmapTextDisabled);

        skinBitmapTextDisabled = value;
        update(false, Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

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
            Utils.hide(label, label.skinBgDisabled);
        }
        else {
            if (Utils.eq(label.skinBgDisabled, null)) {
                Utils.show(label, label.skinBg);
                //Utils.hide(component, component.skinBgDisabled);
            }
            else {
                Utils.hide(label, label.skinBg);
                Utils.show(label, label.skinBgDisabled);
            }
        }

        Utils.show(label, label.skinText);
        Utils.show(label, label.skinBitmapText);
    }

    /**
     * Базовое обновление размеров компонента `Label`.
     */
    static public var updateSizeDefault:SizeUpdater<Label> = function(label) {
        if (label.autosize) {
            var sw:Float = 0;
            var sh:Float = 0;
            
            // Надо получить новые размеры:
            if (label.enabled || Utils.eq(label.skinTextDisabled, null)) {
                if (Utils.noeq(label.skinText, null)) {
                    if (label.skinText.text == label.text) {
                        label.skinText.updateText(true);
                    }
                    else {
                        label.skinText.text = label.text;
                        label.skinText.updateText(false);
                    }

                    label.skinText.x = 0;
                    label.skinText.y = 0;

                    sw = label.skinText.width;
                    sh = label.skinText.height;
                }
            }
            else {
                if (Utils.noeq(label.skinText, null)) {
                    if (label.skinTextDisabled.text == label.text) {
                        label.skinTextDisabled.updateText(true);
                    }
                    else {
                        label.skinTextDisabled.text = label.text;
                        label.skinTextDisabled.updateText(false);
                    }

                    label.skinTextDisabled.x = 0;
                    label.skinTextDisabled.y = 0;

                    sw = label.skinTextDisabled.width;
                    sh = label.skinTextDisabled.height;
                }
            }

            // Растровый текст:
            // ...
            
            // Фон:
            Utils.size(label.skinBg, sw, sh);
            Utils.size(label.skinBgDisabled, label.w, label.h);

            // Задаём новые размеры компоненту: (Без вызова сеттера, для оптимального кода)
            Utils.set(label.w, sw);
            Utils.set(label.h, sh);
        }
        else {
            var sw = label.w - label.paddingLeft - label.paddingRight;
            if (sw < 0)
                sw = 0;

            // Простой текст:
            if (label.enabled || Utils.eq(label.skinTextDisabled, null)) {
                if (Utils.noeq(label.skinText, null)) {
                    if (label.skinText.style.wordWrapWidth == sw && label.skinText.text == label.text) {
                        label.skinText.updateText(true);
                    }
                    else {
                        label.skinText.text = label.text;
                        label.skinText.style.wordWrapWidth = sw;
                        label.skinText.updateText(false);
                    }
    
                    if (Utils.eq(label.align, TextAlign.RIGHT))
                        label.skinText.x = label.w - label.skinText.width - label.paddingRight;
                    else if (Utils.eq(label.align, TextAlign.CENTER))
                        label.skinText.x = (label.w - label.skinText.width) / 2;
                    else
                        label.skinText.x = label.paddingLeft;
                }
            }
            else {
                if (Utils.noeq(label.skinTextDisabled, null)) {
                    if (label.skinTextDisabled.style.wordWrapWidth == sw && label.skinTextDisabled.text == label.text) {
                        label.skinTextDisabled.updateText(true);
                    }
                    else {
                        label.skinTextDisabled.text = label.text;
                        label.skinTextDisabled.style.wordWrapWidth = sw;
                        label.skinTextDisabled.updateText(false);
                    }

                    if (Utils.eq(label.align, TextAlign.RIGHT))
                        label.skinTextDisabled.x = label.w - label.skinTextDisabled.width - label.paddingRight;
                    else if (Utils.eq(label.align, TextAlign.CENTER))
                        label.skinTextDisabled.x = (label.w - label.skinTextDisabled.width) / 2;
                    else
                        label.skinTextDisabled.x = label.paddingLeft;
                }
            }

            // Растровый текст:
            // ...

            // Фон:
            Utils.size(label.skinBg, label.w, label.h);
            Utils.size(label.skinBgDisabled, label.w, label.h);
        }
    }
}