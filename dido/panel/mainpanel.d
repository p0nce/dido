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

        child(3).reflow(availableSpace);
        availableSpace.min.y = child(3).position.max.y;

        child(2).reflow(availableSpace);
        availableSpace.max.y = child(2).position.min.y;

        child(1).reflow(availableSpace);
        availableSpace.min.x = child(1).position.max.x;

        child(0).reflow(availableSpace);
    }
}
