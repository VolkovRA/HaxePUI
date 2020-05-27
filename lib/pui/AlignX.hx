package pui;

/**
 * Горизонтальное выравнивание. (Ось X)
 */
@:enum abstract AlignX(String) to String
{
	/**
	 * Выравнивание по левому краю.
	 */
	var LEFT = "left";
	
	/**
	 * Выравнивание по центру.
	 */
	var CENTER = "center";
	
	/**
	 * Выравнивание по правому краю.
	 */
	var RIGHT = "right";
}