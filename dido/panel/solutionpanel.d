module dido.panel.solutionpanel;

import std.path : baseName;

import dido.buffer.buffer;
import dido.gui;

class SolutionPanel : UIElement
{
public:

    this(UIContext context)
    {
        super(context);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        int widthOfSolutionExplorer = (250 + availableSpace.width / 3) / 2;
        _position.max.x = widthOfSolutionExplorer;
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(34, 34, 34, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        int itemSpace = font.charHeight() + 12;
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
                font.setColor(255, 255, 255, 255);
            else
                font.setColor(200, 200, 200, 255);
            font.renderString(_prettyName[i], marginX, marginY + i * itemSpace);
        }
    }

    void updateState(Buffer[] buffers, int bufferSelect)
    {
        _buffers = buffers;
        _prettyName.length = buffers.length;
        for(int i = 0; i < cast(int)buffers.length; ++i)
        {
            _prettyName[i] = baseName(buffers[i].filePath());
        }
        _bufferSelect = bufferSelect;
    }

private:
    string[] _prettyName;
    Buffer[] _buffers;
    int _bufferSelect;
}
