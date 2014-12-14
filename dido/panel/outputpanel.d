module dido.panel.outputpanel;

import dido.gui;

enum LineType
{
    ERROR,
    SUCCESS,
    COMMAND,
    RESULT,
    EXTERNAL,
}

struct LineOutput
{
    LineType type;
    dstring msg;
}

class OutputPanel : UIElement
{
public:

    enum textPadding = 4;

    this(UIContext context)
    {
        super(context);
        _maxHistory = 1000;
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(8, 9, 10, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);
        /*
        renderer.setColor(30, 30, 30, 255);
        renderer.drawRect(0, 0, _position.width, _position.height);
        */

        int fh = font.charHeight();

        // set camera automatically
        if (4 + _log.length * fh < _position.height)
            _cameraY = 0;
        else
            _cameraY = 4 + _log.length * fh - _position.height;

        for (int i = 0; i < cast(int)(_log.length); ++i)
        {
            final switch(_log[i].type) with (LineType)
            {
                case ERROR:  font.setColor(138, 36, 26); break;
                case SUCCESS: font.setColor(66, 137, 45); break;
                case EXTERNAL: font.setColor(128, 128, 128); break;
                case COMMAND: font.setColor(175, 176, 112); break;
                case RESULT: font.setColor(90, 168, 168); break;
            }            
            int textX = textPadding;
            int textY = -_cameraY + textPadding + i * fh;
            font.renderString!dstring(_log[i].msg, textX, textY);
        }
    }

    void clearLog()
    {
        _log.length = 0;
    }

    void log(LineOutput lo)
    {
        _log ~= lo;
        if (_log.length > _maxHistory)
        {
            size_t toStrip = _log.length - _maxHistory;
            _log = _log[toStrip..$];
        }

    }

private:
    size_t _maxHistory;
    LineOutput[] _log;
    int _cameraY;
}
