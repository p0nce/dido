module dido.panel.menupanel;

import dido.gui;

class MenuPanel : UIElement
{
    this(UIContext context)
    {
        super(context);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.max.y = availableSpace.min.y + 8 + charHeight;
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(14, 14, 14, 230);
        renderer.fillRect(0, 0, _position.width, _position.height);
    }
}
