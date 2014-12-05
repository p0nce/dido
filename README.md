Dido is a specific text editor for the D language.

![alt tag](https://raw.github.com/p0nce/dido/master/screenshots/dido.jpg)

Status: early.

## What's inside

- Multiple cursors editing
- dido contains a small GUI package built on top of SDL2 renderers
- portable graphics, SDL and SDL_ttf are the only dependencies: https://www.libsdl.org/

## Current limitations

- currently not configurable
- DUB integration is minimal
- Multiple views not supported
- only UTF-8 files support (load and save)
- see Issues
- command language is very incomplete
- currently no syntax highlighting

## Inspiration

- dido's internals were heavily inspired by kakoune, a much more advanced and general editor.
https://github.com/mawww/kakoune

- Sublime Text is an inspiration for various things like multiple cursors

- Visual Studio is an inspiration for UI

## Compiling

- Build with DUB (a 2.066+ front-end is required)
- Use recent SDL and SDL_ttf binaries (2.x)

