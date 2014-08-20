module dido.app;

import std.file;
import std.conv;

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

            SDL2Renderer renderer = _window.renderer();
            
            renderer.setViewportFull();
            renderer.setColor(23, 23, 23, 255);
            renderer.clear();

            int width = _window.getWidth();
            int height = _window.getHeight();
            int charWidth = _window.charWidth();
            int charHeight = _window.charHeight();

            int widthOfSolutionExplorer = 250;
            int widthOfLineNumberMargin = charWidth * 5;

            renderer.setColor(34, 34, 34, 255);
            renderer.fillRect(0, 0, widthOfSolutionExplorer, height);

            renderer.setColor(28, 28, 28, 255);
            renderer.fillRect(widthOfSolutionExplorer, 0, widthOfLineNumberMargin, height);

            renderer.setColor(34, 34, 34, 255);
            renderer.fillRect(width - 32, 0, width, height);

            int marginEditor = 16;
            
            for (int i = 0; i < _buffer.lines.length; ++i)
            {
                dstring line = _buffer.lines[i];
                dstring lineNumber = to!dstring(i + 1) ~ " ";
                while (lineNumber.length < 5)
                {
                    lineNumber = " "d ~ lineNumber;
                }
                
                _window.setColor(49, 97, 107);
                _window.renderString(lineNumber, widthOfSolutionExplorer, marginEditor + i * charHeight);

                _window.setColor(250, 250, 250);
                int posX = -_cameraX + widthOfSolutionExplorer + widthOfLineNumberMargin + marginEditor;
                int posY = -_cameraY + marginEditor + i * charHeight;
                
                foreach(dchar ch; line)
                {
                    _window.renderChar(ch, posX, posY);
                    posX += charWidth;
                }
            }

            renderer.present();
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
