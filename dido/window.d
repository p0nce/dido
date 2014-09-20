module dido.window;

import gfm.sdl2;
import dido.gui.font;

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

        _renderer.setBlend(SDL_BLENDMODE_BLEND);

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

    int getWidth()
    {
        return _window.getWidth();
    }

    int getHeight()
    {
        return _window.getHeight();
    }

private:
    SDL2Window _window;
    SDL2Renderer _renderer;
    bool isFullscreen = false;
    bool _initialized;
}