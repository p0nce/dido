module dido.window;

import gfm.sdl2;

class Window
{
public:
    this(SDL2 sdl2)
    {

        
        _window = new SDL2Window(sdl2, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, lastWidth, lastHeight, 
                                 SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);

        _renderer = new SDL2Renderer(_window, 0);

    }

    ~this()
    {
        close();
    }

    void close()
    {

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
        _renderer.setColor(39, 40, 34, 255);

        _renderer.present();
    }

private:

    SDL2Window _window;
    SDL2Renderer _renderer;
    bool isFullscreen = false;

    int lastX = SDL_WINDOWPOS_UNDEFINED;
    int lastY = SDL_WINDOWPOS_UNDEFINED;
    int lastWidth = 1024;
    int lastHeight = 768;
}