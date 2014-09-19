module dido.gui.context;

public import gfm.math;
public import gfm.sdl2;
public import dido.gui.font;

class UIContext
{
public:
    this(SDL2Renderer renderer_, Font font_)
    {
        renderer = renderer_;
        font = font_;
    }

    SDL2Renderer renderer;
    Font font;
}
