module dido.gui.font;

import std.conv;
import gfm.sdl2;
import gfm.image;

final class Font
{
public:
    this(SDL2 sdl2, SDL2Renderer renderer, string fontface, int ptSize)
    {
        _sdl2 = sdl2;
        _renderer = renderer;  
        

        _fontData = cast(ubyte[])(std.file.read(fontface));
        if (0 == stbtt_InitFont(&_font, _fontData.ptr, stbtt_GetFontOffsetForIndex(_fontData.ptr, 0)))
            throw new Exception("Coudln't load font " ~ fontface);

        _scaleFactor = stbtt_ScaleForPixelHeight(&_font, ptSize);

        stbtt_GetFontVMetrics(&_font, &_fontAscent, &_fontDescent, &_fontLineGap);

        int ax;
        stbtt_GetCodepointHMetrics(&_font, 'A', &ax, null);
        _charWidth = cast(int)(0.5 + (ax * _scaleFactor));        
        _charHeight = cast(int)(0.5 + (_fontAscent - _fontDescent + _fontLineGap) * _scaleFactor);

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
            _initialized = false;
        }
    }

    SDL2Texture getCharTexture(dchar ch)
    {
        if (ch == 0)
            ch = 0xFFFD;
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
        // Generate glyph coverage
        int width, height;
        int xoff, yoff;
        ubyte* glyphBitmap = stbtt_GetCodepointBitmap(&_font, _scaleFactor, _scaleFactor, ch , &width, &height, &xoff, &yoff);

        // Copy to a SDL surface
        uint Rmask = 0x00ff0000;
        uint Gmask = 0x0000ff00;
        uint Bmask = 0x000000ff;
        uint Amask = 0xff000000;

        surface = new SDL2Surface(_sdl2, _charWidth, _charHeight, 32, Rmask, Gmask, Bmask, Amask);
        {
            surface.lock();
            scope(exit) surface.unlock();

            // fill with transparent white
            for (int i = 0; i < _charHeight; ++i)
            {
                for (int j = 0; j < _charWidth; ++j)
                {
                    ubyte* dest = &surface.pixels[i * surface.pitch + (j * 4)];
                    dest[0] = 255;
                    dest[1] = 255;
                    dest[2] = 255;
                    dest[3] = 0;
                }
            }

            for (int i = 0; i < height; ++i)
            {
                for (int j = 0; j < width; ++j)
                {
                    ubyte source = glyphBitmap[j + i * width];
                    int destX = j + xoff;
                    int destY = i + yoff + cast(int)(0.5 + _fontAscent * _scaleFactor);

                    if (destX >= 0 && destX < _charWidth)
                    {
                        if (destY >= 0 && destY < _charHeight)
                        {
                            ubyte* dest = &surface.pixels[destY * surface.pitch + (destX * 4)];
                            dest[3] = source; // fully white, but eventually transparent
                        }
                    }
                }
            }
        }

        // Free glyph coverage
        stbtt_FreeBitmap(glyphBitmap);

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
        tex.setColorMod(_r, _g, _b);
        tex.setAlphaMod(_a);
        _renderer.copy(tex, x, y);
    }


private:

    int _r, _g, _b, _a;

    SDL2 _sdl2;
    
    SDL2Renderer _renderer;
    stbtt_fontinfo _font;    
    ubyte[] _fontData;
    int _fontAscent, _fontDescent, _fontLineGap;

    SDL2Texture[dchar] _glyphCache;
    SDL2Surface[dchar] _surfaceCache;
    int _charWidth;
    int _charHeight;
    float _scaleFactor;
    bool _initialized;
}
