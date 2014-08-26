module dido.panel;

import std.conv;

import gfm.math;
import gfm.sdl2;

import dido.window;
import dido.selection;
import dido.buffer;

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

class TextArea : Panel
{
public:

    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;
        int widthOfSolutionExplorer = (250 + availableSpace.width / 3) / 2;

        _position.min.x = widthOfSolutionExplorer;
        _position.min.y = (8 + charHeight);
        _position.max.y -= (8 + charHeight);

        _charWidth = charWidth;
        _charHeight = charHeight; 
    }

    override void render(SDL2Renderer renderer)
    {
        int widthOfLineNumberMargin = _charWidth * 6;
        int widthOfLeftScrollbar = 12;
        int marginScrollbar = 4;

        renderer.setColor(28, 28, 28, 255);
        renderer.fillRect(_position.min.x, _position.min.y, widthOfLineNumberMargin, _position.height);

        renderer.setColor(34, 34, 34, 128);
        renderer.fillRect(_position.max.x - marginScrollbar - widthOfLeftScrollbar, 
                          marginScrollbar, 
                          widthOfLeftScrollbar, 
                          _position.height - marginScrollbar * 2);

        int marginEditor = 16;

        int editPosX = -_cameraX + _position.min.x + widthOfLineNumberMargin + marginEditor;
        int editPosY = -_cameraY + _position.min.y + marginEditor;

        for (int i = 0; i < _buffer.numLines(); ++i)
        {
            dstring line = _buffer.line(i);
            dstring lineNumber = to!dstring(i + 1) ~ " ";
            while (lineNumber.length < 6)
            {
                lineNumber = " "d ~ lineNumber;
            }

            _window.setColor(49, 97, 107, 160);
            _window.renderString(lineNumber,  _position.min.x,  _position.min.y -_cameraY + marginEditor + i * _charHeight);


            int posX = editPosX;
            int posY = editPosY + i * _charHeight;

            foreach(dchar ch; line)
            {
                switch (ch)
                {
                    case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                        _window.setColor(255, 200, 200);
                        break;

                    case '+', '-', '=', '>', '<', '^', ',', '$', '|', '&', '`', '/', '@', '.', '"', '[', ']', '?', ':', '\'', '\\':
                        _window.setColor(255, 255, 106);
                        break;

                    case '(', ')', ';':
                        _window.setColor(255, 255, 150);
                        break;

                    case '{':
                        _window.setColor(108, 108, 128);
                        break;

                    case '}':
                        _window.setColor(108, 108, 138);
                        break;

                    case '\n':
                        ch = ' '; //0x2193; // down arrow
                        _window.setColor(40, 40, 40);
                        break;

                    case ' ':
                        ch = 0x2D1;
                        _window.setColor(60, 60, 70);
                        break;

                    default:
                        _window.setColor(250, 250, 250);
                        break;
                }

                _window.renderChar(ch, posX, posY);
                posX += _charWidth;
            }
        }

        // draw cursors
        SelectionSet selset = _buffer.selectionSet;
        foreach(Selection sel; selset.selections)
        {
            renderSelection(renderer, editPosX, editPosY, sel, _drawCursors);
        }
    }

    void setState(Window window, SelectionBuffer buffer, bool drawCursors)
    {
        _buffer = buffer;
        _window = window;
        _drawCursors = drawCursors;
    }

private:
    int _cameraX = 0;
    int _cameraY = 0;
    int _charWidth;
    int _charHeight;
    SelectionBuffer _buffer;    
    Window _window;
    bool _drawCursors;

    void renderSelection(SDL2Renderer renderer, int offsetX, int offsetY, Selection selection, bool drawCursors)
    {
        // draw the cursor part
        if (drawCursors)
        {
            int startX = offsetX + selection.start.column * _window.charWidth();
            int startY = offsetY + selection.start.line * _window.charHeight();

            renderer.setColor(255, 255, 255, 255);
            renderer.fillRect(startX, startY, 1, _window.charHeight() - 1);
        }

        if (selection.hasSelectedArea)
        {
            int stopX = offsetX + selection.stop.column * _window.charWidth();
            int stopY = offsetY + selection.stop.line * _window.charHeight();

            // draw the cursor part
            renderer.setColor(128, 128, 128, 255);
            renderer.fillRect(stopX, stopY, 1, _window.charHeight() - 1);
        }

        // TODO draw extent
    }
}