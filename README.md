Dido is a specific text editor for the D language.

![alt tag](https://raw.github.com/p0nce/dido/master/screenshots/dido.jpg)

Status: early.

- No syntax coloration currently.

== What's inside ==

- Multiple cursors editing
- dido contains a small GUI package built on top of SDL2 renderers
- configuration file in sdlang: https://github.com/Abscissa/SDLang-D
- portable graphics, SDL is the only dependency: https://www.libsdl.org/

== Current limitations ==

- DUB integration is minimal
- Multiple views not supported
- only UTF-8 files support
- see Issues
- command language is a sub-DSL
- no syntax highlighting

== Inspiration ==

- dido's internals were heavily inspired by kakoune, a much more advanced and general editor.
https://github.com/mawww/kakoune

- Sublime Text is an inspiration for various things like multiple cursors

- Visual Studio is an inspiration for UI


