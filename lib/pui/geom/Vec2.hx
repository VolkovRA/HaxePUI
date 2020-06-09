package pui.geom;

/**
 * Вектор 2D.
 * Описывает скорость и направление движения в двумерном, евклидовом пространстве.
 */
class Vec2 
{
    /**
     * Создать вектор.
     * @param x Ось X.
     * @param y Ось Y.
     */
    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    /**
     * Ось X.
     * По умолчанию: `0`
     */
    public var x:Float;

    /**
     * Ось Y.
     * По умолчанию: `0`
     */
    public var y:Float;

    /**
     * Получить копию вектора.
     * @return Vec2 Копия исходного вектора.
     */
    public function copy():Vec2 {
        return new Vec2(x, y);
    }

    /**
     * Получить длину вектора.
     * @return Длина вектора.
     */
    public function len():Float {
        return Math.sqrt(x*x + y*y);
    }

    /**
     * Нормализовать вектор.
     * Этот вызов приводит длину вектора к `1`, если его текущая длина не равна `0`.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function nrm():Vec2 {
        if (Utils.eq(x, 0) && Utils.eq(y, 0))
            return this;

        var len = Math.sqrt(x*x + y*y);
        x /= len;
        y /= len;
        return this;
    }

    /**
     * Задать вектор.
     * @param x Ось X.
     * @param y Ось Y.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function set(x:Float, y:Float):Vec2 {
        this.x = x;
        this.y = y;
        return this;
    }

    /**
     * Установить параметры текущего вектора в соответствии с переданным.
     * Копирует в текущий вектор значения `x` и `y` из указанного вектора.
     * @param vec Сторонний вектор.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function setFrom(vec:Vec2):Vec2 {
        x = vec.x;
        y = vec.y;
        return this;
    }

    /**
     * Сделать вектор модульным. (Удалить знаки минус)
     * ```
     * x = |x|
     * y = |y|
     * ```
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function abs():Vec2 {
        if (x < 0) x = -x;
        if (y < 0) y = -y;
        return this;
    }

    /**
     * Сложение осей вектора с указанным значением.
     * ```
     * x + v
     * y + v
     * ```
     * @param v Добавляемое значение.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function add(v:Float):Vec2 {
        this.x += v;
        this.y += v;
        return this;
    }

    /**
     * Вычитание из осей вектора указанного значения.
     * ```
     * x - v
     * y - v
     * ```
     * @param v Вычитаемое значение.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function sub(v:Float):Vec2 {
        this.x -= v;
        this.y -= v;
        return this;
    }

    /**
     * Умножение осей вектора на скалярное значение.
     * ```
     * x * v
     * y * v
     * ```
     * @param v Скалярное значение.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function mul(v:Float):Vec2 {
        this.x *= v;
        this.y *= v;
        return this;
    }

    /**
     * Деление осей вектора на скалярное значение.
     * ```
     * x / v
     * y / v
     * ```
     * @param v Скалярное значение.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function div(v:Float):Vec2 {
        this.x /= v;
        this.y /= v;
        return this;
    }

    /**
     * Сложение векторов.
     * Складывает текущий вектор с переданным и возвращает текущий вектор.
     * ```
     * x + x2
     * y + y2
     * ```
     * @param vec2 Добавляемый вектор.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function addVec(vec2:Vec2):Vec2 {
        x += vec2.x;
        y += vec2.y;
        return this;
    }

    /**
     * Вычитание векторов.
     * Вычитает из текущего вектора переданный и возвращает текущий вектор.
     * ```
     * x - x2
     * y - y2
     * ```
     * @param vec2 Вычитаемый вектор.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function subVec(vec2:Vec2):Vec2 {
        x -= vec2.x;
        y -= vec2.y;
        return this;
    }

    /**
     * Умножение векторов.
     * Перемножение осей векторов.
     * ```
     * x * x2
     * y * y2
     * ```
     * @param vec2 Второй вектор.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function mulVec(vec2:Vec2):Vec2 {
        x *= vec2.x;
        y *= vec2.y;
        return this;
    }

    /**
     * Деление векторов.
     * Деление осей векторов.
     * ```
     * x / x2
     * y / y2
     * ```
     * @param vec2 Второй вектор.
     * @return Текущий вектор для записи операций в одну строку.
     */
    public function divVec(vec2:Vec2):Vec2 {
        x /= vec2.x;
        y /= vec2.y;
        return this;
    }
}