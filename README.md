Dido is a specific text editor for the D language.

![alt tag](https://raw.github.com/p0nce/dido/master/screenshots/dido.jpg)

Status: early.

## What's inside

- Multiple cursors editing
- dido contains a small GUI package built on top of SDL2 renderers
- portable graphics, SDL 2.x is the only dependency: https://www.libsdl.org/
- minimal DUB integration

## Current limitations

- currently not configurable
- no file browser
- Multiple views not supported
- only UTF-8 files support (load and save)
- command language is very incomplete
- currently no syntax highlighting
- see Issues for more limitations

## Inspiration

- dido's internals were heavily inspired by kakoune, a much more advanced and general editor.
https://github.com/mawww/kakoune

- Sublime Text is an inspiration for various things like multiple cursors

- Visual Studio is an inspiration for UI

## Compiling

- Build with DUB (a 2.066+ front-end is required)
- Use recent SDL 2.x binaries

