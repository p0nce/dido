module dido.panel;

import gfm.math;
import gfm.sdl2;

import dido.window;

class Panel
{
public:

    abstract void render(SDL2Renderer renderer);

    abstract void reflow(box2i availableSpace, int charWidth, int charHeight);

private:
    box2i _position;
}

class MainPanel : Panel
{
public:
    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;

        foreach(child; children)
            child.reflow(availableSpace, charWidth, charHeight);
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setViewportFull();
        renderer.setColor(23, 23, 23, 255);
        renderer.clear();
        foreach(child; children)
            child.render(renderer);
    }

    Panel[] children;
}

class MenuPanel : Panel
{
    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;
        _position.max.y = availableSpace.min.y + 8 + charHeight;
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setColor(14, 14, 14, 230);
        renderer.fillRect(_position.min.x, _position.min.y,  _position.width, _position.height);
    }
}

class SolutionPanel : Panel
{
    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;
        int widthOfSolutionExplorer = (250 + availableSpace.width / 3) / 2;
        _position.max.x = widthOfSolutionExplorer;
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setColor(34, 34, 34, 255);
        renderer.fillRect(_position.min.x, _position.min.y,  _position.width, _position.height);
    }
}

class CommandLinePanel : Panel
{
public:

    this(Window window)
    {
        _window = window;
        currentCommandLine = "";
        statusLine = "";
    }

    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;
        _position.min.y = availableSpace.max.y - (8 + charHeight);

        _charWidth = charWidth;
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setColor(14, 14, 14, 230);
        renderer.fillRect(_position.min.x, _position.min.y,  _position.width, _position.height);

        {
            // commandline bar at bottom

            int textPosx = _position.min.x + 4 + _charWidth;
            int textPosy = _position.min.y + 4;

            if (_commandLineMode)
            {
                _window.setColor(255, 255, 0, 255);
                _window.renderString(":", _position.min.x + 4, _position.min.y + 4);
                _window.setColor(255, 255, 128, 255);
                _window.renderString(currentCommandLine, textPosx, textPosy);
            }
            else
            {
                // Write status line
                _window.setColor(statusColor.r, statusColor.g, statusColor.b, 255);
                _window.renderString(statusLine, textPosx, textPosy);
            }
        }

    }

    void updateState(bool commandLineMode)
    {
        _commandLineMode = commandLineMode;
    }

    dstring currentCommandLine;
    dstring statusLine;
    vec3i statusColor;

private:
    Window _window;
    int _charWidth;
    bool _commandLineMode;

}