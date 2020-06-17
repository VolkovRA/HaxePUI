# Haxe библиотека UI компонентов для PixiJS

![Скриншот](https://github.com/VolkovRA/HaxePUI/blob/master/preview.png)
[Демо онлайн](https://funnycarrot.ru/demo/pui/ "Посмотреть онлайн демку")

Описание
------------------------------

Pui - это небольшая библиотека для [pixijs](https://github.com/pixijs/pixi.js/ "The HTML5 Creation Engine"),
написананя на Haxe. Она содержит реализацию компонентов для пользовательского
интерфейса (UI), позволяет легко их кастомизировать и многократно использовать.
Пополняется по мере необходимости.

Дизайн этой библиотеки схож с дизайном Feathers, но только в совсем общих чертах.
Перед началом использования вы должны создать тему оформления или взять уже имеющуюся.
(см.: Класс `Theme`) Код библиотеки хорошо прокомментирован.

Не имеет других зависимостей, кроме экстернов PixiJS.

**Важно:**
Эта библиотека написана под последнюю версию pixijs (V5). На текущий момент,
нет качественных Haxe экстернов для этой версии. Вы можете использовать этот
github проект для подключения типов pixijs v5 в Haxe: [https://github.com/notboring/pixi-haxe/tree/pixi5/](https://github.com/notboring/pixi-haxe/tree/pixi5/ "Externs of Pixi.js for Haxe")

Как использовать
------------------------------

```
```

Добавление библиотеки
------------------------------

1. Установите haxelib себе на локальную машину, чтобы вы могли использовать библиотеки Haxe.
2. Установите pui себе на локальную машину, глобально, используя cmd:
```
haxelib git pako https://github.com/VolkovRA/HaxePUI master
```
Синтаксис команды:
```
haxelib git [project-name] [git-clone-path] [branch]
haxelib git minject https://github.com/massiveinteractive/minject.git         # Use HTTP git path.
haxelib git minject git@github.com:massiveinteractive/minject.git             # Use SSH git path.
haxelib git minject git@github.com:massiveinteractive/minject.git v2          # Checkout branch or tag `v2`.
```
3. Добавьте библиотеку pui в ваш Haxe проект.

Дополнительная информация:
 * [Документация Haxelib](https://lib.haxe.org/documentation/using-haxelib/ "Using Haxelib")
 * [Документация компилятора Haxe](https://haxe.org/manual/compiler-usage-hxml.html "Configure compile.hxml")
 * [Документация PixiJS](https://pixijs.download/dev/docs/index.html "PixiJS — The HTML5 Creation Engine")