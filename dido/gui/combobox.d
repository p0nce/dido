module dido.gui.combobox;

import std.algorithm;

import gfm.math;
import dido.gui;

class ComboBox : UIElement
{
public:    

    this(UIContext context, dstring[] choices)
    {
        super(context);
        _choices = choices;
        _select = -1;
        
        _paddingW = 8;
        _paddingH = 4;
        setSelectedChoice(0);        
    }

    final void setSelectedChoice(int n)
    {
        if (_select != n)
        {
            _select = n;
            onChoice(n);
        }
    }

    // Called whenever a combobox is selected.
    void onChoice(int n)
    {
        // do nothing
    }

    override void reflow(box2i availableSpace)
    {
        int width = 2 * _paddingW + longestStringLength() * font.charWidth;
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

        dstring textChoice = choice(_select);
        int heightOfText = font.charHeight;
        int widthOfText = font.charWidth * textChoice.length;
        font.renderString(textChoice, 1 + (position.width - widthOfText) / 2, 1 + (position.height - heightOfText) / 2);

    }

    override bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        if (_choices.length == 0)
            return false;
        setSelectedChoice((_select + 1) % _choices.length);
        return true;
    }

    // Called when mouse move over this Element.
    override void onMouseMove(int x, int y, int dx, int dy)
    {
        
    }

    // Called when mouse enter this Element.
    override void onMouseExit()
    {
    }

    dstring choice(int n)
    {
        return _choices[n];
    }

private:

    int _select;
    int _paddingW;
    int _paddingH;

    dstring[] _choices;

    int longestStringLength()
    {
        int maximum = 0;
        foreach(ref dstring c; _choices)
        {
            if (maximum < c.length)
                maximum = c.length;
        }
        return maximum;
    }
}