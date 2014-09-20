module dido.panel.scrollbar;

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

        _progressStart = 0.45f;
        _progressStop = 0.55f;
        _alpha = 128;
    }

    override void reflow(box2i availableSpace)
    {
        int width = 12;
        int margin = 0;

        _position = availableSpace;

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

    box2i getFocusBox()
    {
        if (_vertical)
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * _position.height);
            int iprogressStop = cast(int)(0.5f + _progressStop * _position.height);
            int x = padding;
            int y = iprogressStart;
            return box2i(x, y, x + _position.width - 2 * padding, y + iprogressStop - iprogressStart);
        }
        else
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * _position.width);
            int iprogressStop = cast(int)(0.5f + _progressStop * _position.width);
            int x = iprogressStart;
            int y = padding;
            return box2i(x, y, x + iprogressStop - iprogressStart, y + _position.height - 2 * padding);
        }

    }


    override void preRender(SDL2Renderer renderer)
    {
        if (isMouseOver())
            renderer.setColor(52, 52, 56, _alpha);
        else
            renderer.setColor(42, 42, 46, _alpha);

        renderer.fillRect(0, 0, _position.width, _position.height);
        
        if (isMouseOver())
            renderer.setColor(194, 194, 194, _alpha);
        else
            renderer.setColor(134, 134, 134, _alpha);

        box2i focus = getFocusBox();
        renderer.fillRect(focus.min.x, focus.min.y, focus.width, focus.height);
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
    ubyte _alpha;
}