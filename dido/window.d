module dido.window;

import gfm.sdl2;
import dido.font;

class Window
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

        _fontNormal = new Font(sdlttf, renderer, "fonts/consola.ttf", 24);
        _fontItalic = new Font(sdlttf, renderer, "fonts/consolai.ttf", 24);
        _fontBold = new Font(sdlttf, renderer, "fonts/consolab.ttf", 24);
        _fontBoldItalic = new Font(sdlttf, renderer, "fonts/consolaz.ttf", 24);

    }

    ~this()
    {
        close();
    }

    void close()
    {
        _fontBold.close();
        _fontBoldItalic.close();
        _fontItalic.close();
        _fontNormal.close();

        _renderer.close();
        _window.close();
    }

    void toggleFullscreen()
    {
        isFullscreen = !isFullscreen;
        if (isFullscreen)
            _window.setFullscreenSetting(SDL_WINDOW_FULLSCREEN_DESKTOP);
        else
            _window.setFullscreenSetting(0);
    }

    void render()
    {
        _renderer.setViewportFull();
        _renderer.setColor(12, 12, 12, 255);
        _renderer.clear();

        renderString(_fontNormal, "Hello", 15, 15);
        renderString(_fontBold, "Hello", 15, 60);
        renderString(_fontItalic, "Hello", 15, 120);
        renderString(_fontBoldItalic, "Hello", 15, 180);

        _renderer.present();
    }

    SDL2Renderer renderer()
    {
        return _renderer;
    }

    void renderString(Font font, string s, int x, int y)
    {
        foreach(dchar ch; s)
        {
            SDL2Texture tex = font.getCharTexture(ch);

            _renderer.copy(tex, x, y);
            x += tex.width();
        }
    }

private:

    SDL2Window _window;
    SDL2Renderer _renderer;
    bool isFullscreen = false;

    Font _fontNormal, _fontItalic, _fontBold, _fontBoldItalic;

}