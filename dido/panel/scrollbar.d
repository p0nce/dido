module dido.panel.scrollbar;

import gfm.math;
import dido.gui;

class ScrollBar : UIElement
{
public:

    this(UIContext context, bool vertical)
    {
        super(context);
        _vertical = vertical;

        _progressStart = 0.45f;
        _progressStop = 0.55f;
    }

    override void reflow(box2i availableSpace)
    {
        int width = 10;
        int margin = 2;

        _position = availableSpace;

        if (_vertical)
        {
            _position.min.y += margin;
            _position.max.y -= margin;
            _position.max.x -= margin;
            _position.min.x = _position.max.x - width;
        }
        else
        {
            _position.min.x += margin;
            _position.max.x -= margin;
            _position.max.y -= margin;
            _position.min.y = _position.max.y - width;
        }
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(34, 34, 34, 32);
        renderer.fillRect(0, 0, _position.width, _position.height);

        
        renderer.setColor(130, 130, 140, 32);
        if (_vertical)
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * _position.height);
            int iprogressStop = cast(int)(0.5f + _progressStop * _position.height);
            renderer.fillRect(1, iprogressStart, _position.width - 2, iprogressStop - iprogressStart);
        }
        else
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * _position.width);
            int iprogressStop = cast(int)(0.5f + _progressStop * _position.width);
            renderer.fillRect(iprogressStart, 1, iprogressStop - iprogressStart, _position.height - 2);
        }
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
    vec4i _color;

}