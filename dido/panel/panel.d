module dido.panel.panel;

import std.conv;
import std.path;

public import gfm.math.box;
public import gfm.sdl2;

class Panel
{
public:

    abstract void render(SDL2Renderer renderer);

    abstract void reflow(box2i availableSpace, int charWidth, int charHeight);

    final box2i position() pure const nothrow
    {
        return _position;
    }

protected:
    box2i _position;
}
