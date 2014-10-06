module dido.gui.button;

import std.algorithm;

import gfm.math;
import dido.gui;

class UIButton : UIElement
{
public:    

    this(UIContext context, dstring label)
    {
        super(context);
        _label = label;
        
        _paddingW = 8;
        _paddingH = 4;
    }

    override void reflow(box2i availableSpace)
    {
        int width = 2 * _paddingW + _label.length * font.charWidth;
        int height = 2 * _paddingH + font.charHeight;
        _position = box2i(availableSpace.min.x, availableSpace.min.y, availableSpace.min.x + width, availableSpace.min.y + height);        
    }

    override void preRender(SDL2Renderer renderer)
    {
        if (isMouseOver())
        {
            renderer.setColor(30, 27, 27, 255);
            renderer.fillRect(1, 1, _position.width - 2, _position.height -2);
        }

        renderer.setColor(70, 67, 67, 255);
        renderer.drawRect(0, 0, _position.width, _position.height);       

        if (isMouseOver())
            font.setColor(255, 255, 200);
        else
            font.setColor(200, 200, 200);

        dstring textChoice = _label;
        int heightOfText = font.charHeight;
        int widthOfText = font.charWidth * textChoice.length;
        font.renderString(textChoice, 1 + (position.width - widthOfText) / 2, 1 + (position.height - heightOfText) / 2);
    }

private:
    dstring _label;
    int _paddingW;
    int _paddingH;
}