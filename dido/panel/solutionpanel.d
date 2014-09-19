module dido.panel.solutionpanel;

import std.path : baseName;

import dido.panel.panel;
import dido.buffer;
import dido.gui.font;

class SolutionPanel : Panel
{
public:
    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;
        int widthOfSolutionExplorer = (250 + availableSpace.width / 3) / 2;
        _position.max.x = widthOfSolutionExplorer;
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setViewport(_position.min.x, _position.min.y, _position.width, _position.height);
        renderer.setColor(34, 34, 34, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        int itemSpace = _font.charHeight() + 12;
        int marginX = 16;
        int marginY = 16;
        
        for(int i = 0; i < cast(int)_buffers.length; ++i)
        {   
            renderer.setColor(25, 25, 25, 255);
            int rectMargin = 4;
            renderer.fillRect(marginX - rectMargin, marginY - rectMargin + i * itemSpace, _position.width - 2 * (marginX - rectMargin), itemSpace - 4);
        }

        for(int i = 0; i < cast(int)_buffers.length; ++i)
        {
            if (i == _bufferSelect)
                _font.setColor(255, 255, 255, 255);
            else
                _font.setColor(200, 200, 200, 255);
            _font.renderString(_prettyName[i], marginX, marginY + i * itemSpace);
        }

        renderer.setViewportFull();
    }

    void updateState(Font font, Buffer[] buffers, int bufferSelect)
    {
        _buffers = buffers;
        _prettyName.length = buffers.length;
        for(int i = 0; i < cast(int)buffers.length; ++i)
        {
            _prettyName[i] = baseName(buffers[i].filePath());
        }
        _font = font;
        _bufferSelect = bufferSelect;
    }

private:
    string[] _prettyName;
    Buffer[] _buffers;
    Font _font;
    int _bufferSelect;
}
