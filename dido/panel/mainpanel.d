module dido.panel.mainpanel;

import dido.gui;

class MainPanel : UIElement
{
public:    
    this(UIContext context)
    {
        super(context);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;

        // reflow horizontal bars first
        child(4).reflow(availableSpace);


        child(3).reflow(availableSpace);
        availableSpace.min.y = child(3).position.max.y;

        child(2).reflow(availableSpace);
        availableSpace.max.y = child(2).position.min.y;

        child(1).reflow(availableSpace);
        availableSpace.min.x = child(1).position.max.x;

        child(0).reflow(availableSpace);
    }
}

class CornerPanel : UIElement
{
public:
    this(UIContext context, int width, int height)
    {
        super(context);
        _width = width;
        _height = height;
    }

    override void preRender(SDL2Renderer renderer)
    {
        SDL2Texture tex = context.image("corner");
        renderer.copy(context.image("corner"), 0, 0);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.min.x = _position.max.x - _width;
        _position.min.y = _position.max.y - _height;
    }

private:
    int _width;
    int _height;
}

