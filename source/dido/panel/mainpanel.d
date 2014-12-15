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

        int widthOfWestPanel = (250 + availableSpace.width / 3) / 2;
        
        box2i spaceForWest = availableSpace;
        spaceForWest.max.x = widthOfWestPanel;

        child(1).reflow(spaceForWest);


        availableSpace.min.x = widthOfWestPanel;
        child(0).reflow(availableSpace);
    }
}



