module dido.panel.commandlinepanel;

import gfm.math;
import dido.gui;

class CommandLinePanel : UIElement
{
public:

    this(UIContext context)
    {
        super(context);
        currentCommandLine = "";
        statusLine = "";
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.min.y = availableSpace.max.y - (8 + charHeight);
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(14, 14, 14, 230);
        renderer.fillRect(0, 0, _position.width, _position.height);

        {
            // commandline bar at bottom

            int textPosx = 4 + charWidth;
            int textPosy = 4;

            if (_commandLineMode)
            {
                font.setColor(255, 255, 0, 255);
                font.renderString(":", 4, 4);
                font.setColor(255, 255, 128, 255);
                font.renderString(currentCommandLine, textPosx, textPosy);
            }
            else
            {
                // Write status line
                font.setColor(statusColor.r, statusColor.g, statusColor.b, 255);
                font.renderString(statusLine, textPosx, textPosy);
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
    bool _commandLineMode;
}
