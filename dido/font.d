module dido.font;

import std.conv;
import gfm.sdl2;

final class Font
{
public:
    this(SDLTTF sdlttf, SDL2Renderer renderer, string fontface, int ptSize)
    {
        _sdlttf = sdlttf;
        _renderer = renderer;

        _font = new SDLFont(_sdlttf, fontface, ptSize);

        _charWidth = makeCharTexture('A').width();
        _charHeight = makeCharTexture('A').height();

        _initialized = true;

        _r = 255;
        _g = 255;
        _b = 255;
        _a = 255;
    }

    ~this()
    {
        close();
    }

    void close()
    {
        if (_initialized)
        {
            foreach (tex; _glyphCache)
                tex.close();
            _font.close();
            _initialized = false;
        }
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

    int charWidth() pure const nothrow
    {
        return _charWidth;
    }

    int charHeight() pure const nothrow
    {
        return _charHeight;
    }

    void setColor(int r, int g, int b, int a = 255)
    {
        _r = r;
        _g = g;
        _b = b;
        _a = a;
    }

    void renderString(dstring s, int x, int y)
    {
        foreach(dchar ch; s)
        {
            SDL2Texture tex = getCharTexture(ch);
            tex.setColorMod(_r, _g, _b);
            tex.setAlphaMod(_a);
            _renderer.copy(tex, x, y);
            x += tex.width();
        }
    }

    void renderChar(dchar ch, int x, int y)
    {
        SDL2Texture tex = getCharTexture(ch);
        tex.setColorMod(_r, _g, _b);
        _renderer.copy(tex, x, y);
    }


private:

    int _r, _g, _b, _a;

    SDLTTF _sdlttf;
    SDL2Renderer _renderer;
    SDLFont _font;
    SDL2Texture[dchar] _glyphCache;
    int _charWidth;
    int _charHeight;
    bool _initialized;
}
