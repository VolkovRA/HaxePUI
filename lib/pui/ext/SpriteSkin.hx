package pui.ext;

import pixi.core.textures.Texture;
import pixi.core.sprites.Sprite;
import js.lib.Object;

/**
 * Спрайтовый скин.
 * 
 * Это обычный спрайт PixiJS с немного изменённым функционалом
 * для удобного скинования компонентов.
 * 
 * Отличия от базового спрайта:
 * 1. Добавлены свойства отступов: `paddingTop`, `paddingLeft`,
 *    `paddingRight` и `paddingBottom` для задания отступов текстуры
 *    за края компонента. Это полезно для скинов с эффектами тени,
 *    свечения, размытия или т.п. выходящих за рамки компонента.
 * 2. Изменены сеттеры: `width` и `height`, для корректного
 *    назначения размеров текстуры с учётом отступов. Теперь они
 *    расчитывают размер из базового размера текстуры, а не из
 *    содержимого спрайта или его потомков. Это делает расчёты
 *    намного быстрее и стабильнее.
 */
class SpriteSkin extends Sprite
{
    /**
     * Создать спрайт с отступами.
     * @param texture Исходная текстура.
     */
    public function new(?texture:Texture) {
        super(texture);
        
        Object.defineProperty(this, "width", {
            set: function(value:Dynamic) {
                scale.x = (value + paddingLeft + paddingRight) / this.texture.width;
            }
        });
        Object.defineProperty(this, "height", {
            set: function(value:Dynamic) {
                scale.y = (value + paddingTop + paddingBottom) / this.texture.height;
            }
        });
    }

    /**
     * Отступ сверху. (px)
     */
    public var paddingTop:Float = 0;

    /**
     * Отступ слева. (px)
     */
    public var paddingLeft:Float = 0;

    /**
     * Отступ справа. (px)
     */
    public var paddingRight:Float = 0;

    /**
     * Отступ снизу. (px)
     */
    public var paddingBottom:Float = 0;
}