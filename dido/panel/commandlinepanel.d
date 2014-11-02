module dido.panel.commandlinepanel;

import gfm.math;
import dido.gui;

import dido.panel.textarea;
import dido.buffer.buffer;

static immutable vec3i statusGreen = vec3i(0, 255, 0);
static immutable vec3i statusYellow = vec3i(255, 255, 0);
static immutable vec3i statusRed = vec3i(255, 0, 0);


class CommandLinePanel : UIElement
{
public:

    int margin = 4;

    this(UIContext context)
    {
        super(context);
        _statusLine = "";
        _buffer = new Buffer();
        _textArea = new TextArea(context, margin, false, false);
        addChild(_textArea);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.min.y = availableSpace.max.y - (2 * margin + charHeight);

        availableSpace = _position;
        availableSpace.min.x += charWidth;
        _textArea.reflow(availableSpace);
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(15, 14, 14, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);        

        {
            // commandline bar at bottom

            int textPosx = 4 + charWidth;
            int textPosy = 4;

            if (_commandLineMode)
            {
                font.setColor(255, 255, 0, 255);
                font.renderString(":", 4, 4);
            }
            else
            {
                // Write status line
                font.setColor(_statusColor.r, _statusColor.g, _statusColor.b, 255);
                font.renderString(_statusLine, textPosx, textPosy);
            }
        }
    }

    void updateMode(bool commandLineMode)
    {
        _commandLineMode = commandLineMode;
        _textArea.setVisible(commandLineMode);
    }

    void updateCursorState(bool showCursors)
    {
        _textArea.setState(_buffer, showCursors);
    }

    void greenMessage(dstring msg)
    {
        _statusLine = msg;
        _statusColor = statusGreen;
    }

    void redMessage(dstring msg)
    {
        _statusLine = msg;
        _statusColor = statusRed;
    }

    dstring getCommandLine()
    {
        return _buffer.getContent();
    }    

    Buffer buffer()
    {
        return _buffer;
    }

    TextArea textArea()
    {
        return _textArea;
    }

private:
    bool _commandLineMode;
    TextArea _textArea;
    Buffer _buffer;

    dstring _statusLine;
    vec3i _statusColor;
}
