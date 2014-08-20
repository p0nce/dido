module dido.app;

import std.file;
import gfm.sdl2;
import gfm.math;


import dido.buffer;
import dido.window;

final class App
{
public:
    this(string path)
    {
        _buffer = new Buffer();
        _buffer.loadFromFile(path);


        _finished = false;

        _sdl2 = new SDL2(null);
        _sdlttf = new SDLTTF(_sdl2);
        _window = new Window(_sdl2, _sdlttf);
    }

    ~this()
    {
        close();
    }

    void close()
    {
//        _buffer.close();
        _window.close();
        _sdlttf.close();
        _sdl2.close();
    }

    void mainLoop()
    {
        while(!_sdl2.wasQuitRequested() && !_finished)
        {

            SDL_Event event;
            while (_sdl2.pollEvent(&event))
            {
                switch (event.type)
                {
                    case SDL_KEYDOWN:
                        {
                            auto key = event.key.keysym;
                            if (key.sym == SDLK_RETURN && ((key.mod & KMOD_ALT) != 0))
                                _window.toggleFullscreen();
                            else if (key.sym == SDLK_ESCAPE)
                                _finished = true;
                            break;
                        }
                    default:
                        break;
                }
            }

            _window.renderBegin();

            for (int i = 0; i < _buffer.lines.length; ++i)
            {
                dstring line = _buffer.lines[i];

                int posX = -_cameraX + 16;
                int posY = -_cameraY + i * _window.charHeight();
                foreach(dchar ch; line)
                {
                    _window.renderChar(ch, posX, posY);
                    posX += _window.charWidth();
                }
            }

            _window.renderEnd();
        }
    }


private:

    int _cameraX = 0;
    int _cameraY = 0;

    bool _finished;
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;
    Buffer _buffer;
}
