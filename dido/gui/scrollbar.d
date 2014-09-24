module dido.gui.scrollbar;

import gfm.math;
import dido.gui;

class ScrollBar : UIElement
{
public:

    int widthOfScrollbar = 8;
    int padding = 4;

    this(UIContext context, bool vertical)
    {
        super(context);
        _vertical = vertical;

        setState(0.45f, 0.55f);
    }

    override void reflow(box2i availableSpace)
    {
        int margin = 0;

        _position = availableSpace;
        _buttonSize = (widthOfScrollbar + 2 * padding);

        if (_vertical)
        {
            _position.min.y += margin;
            _position.max.y -= margin;
            _position.max.x -= margin;
            _position.min.x = _position.max.x - (widthOfScrollbar + 2 * padding);
        }
        else
        {
            _position.min.x += margin;
            _position.max.x -= margin;
            _position.max.y -= margin;
            _position.min.y = _position.max.y - (widthOfScrollbar + 2 * padding);
        }
    }

    override void preRender(SDL2Renderer renderer)
    {
        // Do not display useless scrollbar
        if (_progressStart <= 0.0f && _progressStop >= 1.0f)
            return;

        if (isMouseOver())
            renderer.setColor(42, 42, 46, 255);
        else
            renderer.setColor(32, 32, 36, 255);

        renderer.fillRect(0, 0, _position.width, _position.height);
        
        if (isMouseOver())
            renderer.setColor(140, 140, 140, 255);
        else
            renderer.setColor(100, 100, 100, 255);

        box2i focus = getFocusBox();
        roundedRect(renderer, focus);
    }

    void roundedRect(SDL2Renderer renderer, box2i b)
    {
        if (b.height > 2 && b.width > 2)
        {
            renderer.fillRect(b.min.x + 1, b.min.y    , b.width - 2, 1);
            renderer.fillRect(b.min.x    , b.min.y + 1, b.width    , b.height - 2);
            renderer.fillRect(b.min.x + 1, b.max.y - 1, b.width - 2, 1);
        }
        else
            renderer.fillRect(b.min.x, b.min.y, b.width, b.height);
    }

    void setState(float progressStart, float progressStop)
    {
        _progressStart = clamp!float(progressStart, 0.0f, 1.0f);
        _progressStop = clamp!float(progressStop, 0.0f, 1.0f);
        if (_progressStop < _progressStart)
            _progressStop = _progressStart;
    }   

private:
    bool _vertical;
    float _progressStart;
    float _progressStop;
    int _buttonSize;

    box2i getFocusBox()
    {
        if (_vertical)
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * (_position.height - 2 * _buttonSize));
            int iprogressStop = cast(int)(0.5f + _progressStop * (_position.height - 2 * _buttonSize));
            int x = padding;
            int y = iprogressStart + _buttonSize;
            return box2i(x, y, x + _position.width - 2 * padding, y + iprogressStop - iprogressStart);
        }
        else
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * (_position.width - 2 * _buttonSize));
            int iprogressStop = cast(int)(0.5f + _progressStop * (_position.width - 2 * _buttonSize));
            int x = iprogressStart + _buttonSize;
            int y = padding;
            return box2i(x, y, x + iprogressStop - iprogressStart, y + _position.height - 2 * padding);
        }
    }

    void drawExtremity(int x, int y, int width)
    {

    }
}