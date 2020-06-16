import pui.ui.ListItemLabel;

class CustomListItem extends ListItemLabel 
{
    public function new() {
        super();

        this.debug = true;
        this.h = Math.random() * 70 + 30;
        this.w = Math.random() * 200 + 150;
    }
}