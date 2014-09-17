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

        SDL2Texture tempTexture;
        SDL2Surface tempSurface;
        makeCharTexture('A', tempTexture, tempSurface);
        _charWidth = tempTexture.width();
        _charHeight = tempSurface.height();

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
            foreach (tex; _surfaceCache)
                tex.close();
            _font.close();
            _initialized = false;
        }
    }

    SDL2Texture getCharTexture(dchar ch)
    {
        try
        {
            if (! (ch in _glyphCache))
            {
                SDL2Texture tex;
                SDL2Surface surf;
                makeCharTexture(ch, tex, surf);
                _glyphCache[ch] = tex;
                _surfaceCache[ch] = surf;
            }

            return _glyphCache[ch];
        }
        catch(SDL2Exception e)
        {
            if (ch == 0xFFFD)
                return null;

            // invalid glyph, return replacement character glyph
            return getCharTexture(0xFFFD);
        }
    }

    void makeCharTexture(dchar ch, out SDL2Texture texture, out SDL2Surface surface)
    {
        surface = _font.renderGlyphBlended(ch, SDL_Color(255, 255, 255, 255));
        texture = new SDL2Texture(_renderer, surface);
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

    void renderString(StringType)(StringType s, int x, int y)
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
        if (tex !is null)
        {
            tex.setColorMod(_r, _g, _b);
            _renderer.copy(tex, x, y);
        }
    }


private:

    int _r, _g, _b, _a;

    SDLTTF _sdlttf;
    SDL2Renderer _renderer;
    SDLFont _font;
    SDL2Texture[dchar] _glyphCache;
    SDL2Surface[dchar] _surfaceCache;
    int _charWidth;
    int _charHeight;
    bool _initialized;
}
