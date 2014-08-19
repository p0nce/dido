module app;

import std.typecons;
import gfm.sdl2;
import gfm.sdl2.sdlttf;

import gfm.sdl2;
import gfm.math;
import std.logger;
import std.file;
import dido;


void main()
{    
    Logger logger = new NullLogger();
	auto sdl2 = scoped!SDL2(null);

    

    string wholeFile = cast(string)(std.file.read("app.d"));


    auto _window = scoped!Window(sdl2);

    bool finished = false;

    while(!sdl2.wasQuitRequested() && !finished)
    {

        SDL_Event event;
        while (sdl2.pollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_KEYDOWN:
                    {
                        auto key = event.key.keysym;
                        if (key.sym == SDLK_RETURN && ((key.mod & KMOD_ALT) != 0))
                            _window.toggleFullscreen();
                        else if (key.sym == SDLK_ESCAPE)
                            finished = true;
                        break;
                    }
                default:
                    break;
            }
        }

        _window.render();
    }
}
