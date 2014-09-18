module dido.panel.commandlinepanel;

import gfm.math;

import dido.panel.panel;
import dido.font;

class CommandLinePanel : Panel
{
public:

    this(Font font)
    {
        _font = font;
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
                _font.setColor(255, 255, 0, 255);
                _font.renderString(":", _position.min.x + 4, _position.min.y + 4);
                _font.setColor(255, 255, 128, 255);
                _font.renderString(currentCommandLine, textPosx, textPosy);
            }
            else
            {
                // Write status line
                _font.setColor(statusColor.r, statusColor.g, statusColor.b, 255);
                _font.renderString(statusLine, textPosx, textPosy);
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
    Font _font;
    int _charWidth;
    bool _commandLineMode;

}
