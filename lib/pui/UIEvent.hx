package pui;

/**
 * Событие графического интерфейса.
 * 
 * Это перечисление всех доступных событий библиотеки компонентов pui.
 * Пожалуйста, **не путайте** эти события с стандартными событиями в pixijs `Event`.
 * Все события `UIEvent` реализуются только компонентами этой библиотеки.
 * 
 * В некоторых случаях, события `UIEvent` могут дублировать стандартные
 * события pixi, однако, они полностью отличаются друг от друга.
 * 
 * События `UIEvent` - это не замена, а дополнение к уже имеющимся событиям в pixijs.
 * Они необходимы для реализации нужного поведени и функционала.
 * 
 * @see Стандартные события pixijs: `pui.Event`
 */
@:enum abstract UIEvent(String) to String
{
    /**
     * Компонент интерфейса изменил своё состояние.
     */
    var STATE = "UIState";

    /**
     * Компонент интерфейса обновился.
     */
    var UPDATE = "UIUpdate";

	/**
     * Нажатие по компоненту интерфейса.
     * 
     * Событие нажатия реализуется собственным алгоритмом библиотеки компонентов.
	 */
    var CLICK = "UIClick";

    /**
     * Двойное нажатие по компоненту интерфейса.
     * 
     * Срабатывает при быстром, кратковременном двойном клике на компоненте
     * в течении короткого промежутка времени и в одном месте.
     */
    var DOUBLE_CLICK = "UIDoubleClick";
}