package pui.ui;

import pui.ui.Component;

/**
 * Элемент списка с текстовой меткой.
 * Отображает данные списка как строку.
 */
class ListItemLabel extends ListItem
{
    /**
     * Тип компонента `ListItemLabel`.
     */
    static public inline var TYPE:String = "ListItemLabel";

    /**
     * Создать элемент списка.
     */
    public function new() {
        super();

        this.componentType = TYPE;

        Utils.set(this.updateLayers, ListItemLabel.defaultLayers);
        Utils.set(this.updateSize, ListItemLabel.defaultSize);
    }

    /**
     * Текстовая метка.
     * Не может быть `null`
     */
    public var label(default, null):Label = new Label();

    override function set_enabled(value:Bool):Bool {
        label.enabled = value;
        return super.set_enabled(value);
    }

    override function set_data(value:Dynamic):Dynamic {
        label.text = value;
        return super.set_data(value);
    }



    /////////////////////////////////
    //   СЛОИ И ПОЗИЦИАНИРОВАНИЕ   //
    /////////////////////////////////

    /**
     * Обычное положение слоёв элемента списка.
     */
    static public var defaultLayers:LayersUpdater<ListItemLabel> = function(item) {
        Component.defaultLayers(item);
        Utils.show(item, item.label);
    }

    /**
     * Обычное позицианирование элемента списка.
     */
    static public var defaultSize:SizeUpdater<ListItemLabel> = function(item) {
        Component.defaultSize(item);
        item.label.w = item.w;
        item.label.h = item.h;
        item.label.update(true);
    }
}