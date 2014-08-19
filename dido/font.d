module dido.font;

import std.conv;
import gfm.sdl2;

class Font
{
public:
    this(SDLTTF sdlttf, SDL2Renderer renderer, string fontface, int ptSize)
    {
        _sdlttf = sdlttf;
        _renderer = renderer;

        _font = new SDLFont(_sdlttf, fontface, ptSize);
    }

    ~this()
    {
        close();
    }

    void close()
    {
        foreach (tex; _glyphCache)
            tex.close();
        _font.close();
    }

    SDL2Texture getCharTexture(dchar ch)
    {
        if (! (ch in _glyphCache))
            _glyphCache[ch] = makeCharTexture(ch);

        return _glyphCache[ch];
    }

    SDL2Texture makeCharTexture(dchar ch)
    {
        SDL2Surface surface = _font.renderGlyphBlended(ch, SDL_Color(255, 255, 255, 255));
        return new SDL2Texture(_renderer, surface);
    }


private:
    SDLTTF _sdlttf;
    SDL2Renderer _renderer;
    SDLFont _font;
    SDL2Texture[dchar] _glyphCache;
}
