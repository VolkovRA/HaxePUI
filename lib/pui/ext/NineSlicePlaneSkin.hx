package pui.ext;

import pixi.core.textures.Texture;
import pixi.mesh.NineSlicePlane;
import js.Syntax;

/**
 * Девяти-фрагментный скин.
 * 
 * Это обычный `NineSlicePlane` PixiJS с немного изменённым функционалом
 * для удобного скинования компонентов.
 * 
 * Отличия от базового спрайта:
 * 1. Добавлены свойства отступов: `paddingTop`, `paddingLeft`,
 *    `paddingRight` и `paddingBottom` для задания отступов текстуры
 *    за края компонента. Это полезно для скинов с эффектами тени,
 *    свечения, размытия или т.п. выходящих за рамки компонента.
 * 2. Переопределены сеттеры: `width` и `height`, для корректного
 *    назначения размеров текстуры с учётом отступов и масштабирования.
 * 3. Скалирование `scale` теперь используется как значение для
 *    обозначения "разрешения" исходной текстуры для корректной
 *    нарезки сегментов у масштабированных текстур.
 */
class NineSlicePlaneSkin extends NineSlicePlane
{
    /**
     * Создать спрайт с отступами.
     * @param texture Исходная текстура.
     */
    public function new(?texture:Texture) {
        super(texture);
        
        /**
         * Класс `NineSlicePlane` переопределяет `width` и `height`,
         * устанавливая логику работы, отличную от `Container`.
         * Вообщем, теперь `width` не является проекцией `scale.x`,
         * это отдельное, самостоятельное значение.
         * 
         * Для корректной работы с масштабированными текстурами, нам
         * необходимо расчитать коэффициент и перевести размеры в 
         * оригинальный масштаб: `(1/scale.x)`
         */

        Syntax.code('Object.defineProperty(this,"width",{set:function(value){Object.getOwnPropertyDescriptor({0}.prototype,"width").set.call(this,(value+{1}+{2})*({3}===0?0:(1/{3})))} });', NineSlicePlane, paddingLeft, paddingRight, scale.x);
        Syntax.code('Object.defineProperty(this,"height",{set:function(value){Object.getOwnPropertyDescriptor({0}.prototype,"height").set.call(this,(value+{1}+{2})*({3}===0?0:(1/{3})))} });', NineSlicePlane, paddingTop, paddingBottom, scale.y);
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