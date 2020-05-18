package pui;

/**
 * Выравнивание текста по горизонтали.
 */
@:enum abstract TextAlign(String) to String
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