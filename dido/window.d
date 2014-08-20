module dido.window;

import gfm.sdl2;
import dido.font;

final class Window
{
public:
    this(SDL2 sdl2, SDLTTF sdlttf)
    {

        int initialWidth = 800;
        int initialHeight = 700;

        _window = new SDL2Window(sdl2, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, initialWidth, initialHeight, 
                                 SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);

        _window.setTitle("Dido v0.0.1");
        _renderer = new SDL2Renderer(_window, 0);

        _fontNormal = new Font(sdlttf, renderer, "fonts/consola.ttf", 14);
        _fontItalic = new Font(sdlttf, renderer, "fonts/consolai.ttf", 14);
        _fontBold = new Font(sdlttf, renderer, "fonts/consolab.ttf", 14);
        _fontBoldItalic = new Font(sdlttf, renderer, "fonts/consolaz.ttf", 14);
        _r = 255;
        _g = 255;
        _b = 255;
        _a = 255;
        _initialized = true;
    }

    ~this()
    {
        close();
    }

    void close()
    {
        if (_initialized)
        {
            _fontBold.close();
            _fontBoldItalic.close();
            _fontItalic.close();
            _fontNormal.close();

            _renderer.close();
            _window.close();
            _initialized = false;
        }
    }

    void toggleFullscreen()
    {
        isFullscreen = !isFullscreen;
        if (isFullscreen)
            _window.setFullscreenSetting(SDL_WINDOW_FULLSCREEN_DESKTOP);
        else
            _window.setFullscreenSetting(0);
    }



    SDL2Renderer renderer()
    {
        return _renderer;
    }

    void renderString(dstring s, int x, int y)
    {
        foreach(dchar ch; s)
        {
            SDL2Texture tex = _fontNormal.getCharTexture(ch);
            tex.setColorMod(_r, _g, _b);
            tex.setAlphaMod(_a);
            _renderer.copy(tex, x, y);
            x += tex.width();
        }
    }

    void renderChar(dchar ch, int x, int y)
    {
        SDL2Texture tex = _fontNormal.getCharTexture(ch);
        tex.setColorMod(_r, _g, _b);
        _renderer.copy(tex, x, y);
    }

    int charWidth()
    {
        return _fontNormal.charWidth();
    }

    int charHeight()
    {
        return _fontNormal.charHeight() + 1;
    }

    int getWidth()
    {
        return _window.getWidth();
    }

    int getHeight()
    {
        return _window.getHeight();
    }

    void setColor(int r, int g, int b, int a = 255)
    {
        _r = r;
        _g = g;
        _b = b;
        _a = a;
    }

private:
    int _r, _g, _b, _a;

    SDL2Window _window;
    SDL2Renderer _renderer;
    bool isFullscreen = false;
    bool _initialized;

    Font _fontNormal, _fontItalic, _fontBold, _fontBoldItalic;
}