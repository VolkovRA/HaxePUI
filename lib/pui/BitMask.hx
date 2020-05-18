package pui;

/**
 * Битовая маска.
 * Используется для управления сразу нескольким количество флагов: `true` и `false`.
 * 
 * Инструменты для работы с маской:
 *   * `Utils.flagsAND` - Проверка наличия флагов в битовой маске.
 *   * `Utils.flagsOR` - Проверка наличия хотя бы одного флага в битовой маске.
 *   * `Utils.flagsIS` - Проверка идентичности маски конкретному флагу/флагам.
 * 
 * Сложение флагов:
 * ```
 * trace(Component.UPDATE_LAYERS | Component.UPDATE_SIZE);
 * ```
 * 
 * @see Битовая маска: https://ru.wikipedia.org/wiki/%D0%91%D0%B8%D1%82%D0%BE%D0%B2%D0%B0%D1%8F_%D0%BC%D0%B0%D1%81%D0%BA%D0%B0
 */
 typedef BitMask = Int;