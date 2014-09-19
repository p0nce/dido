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
    }

    override void reflow(box2i availableSpace)
    {
        int width = 12;
        int margin = 4;

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
        renderer.setColor(34, 34, 34, 128);
        renderer.fillRect(0, 0, _position.width, _position.height);
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

}