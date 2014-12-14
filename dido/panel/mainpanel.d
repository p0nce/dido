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
        child(5).reflow(availableSpace);


        child(4).reflow(availableSpace);
        availableSpace.min.y = child(4).position.max.y;

        child(3).reflow(availableSpace);
        availableSpace.max.y = child(3).position.min.y;

        int widthOfSolutionExplorer = (250 + availableSpace.width / 3) / 2;
        box2i spaceForSolutionPanel = availableSpace;
        spaceForSolutionPanel.max.y = cast(int)(0.5 + spaceForSolutionPanel.min.y * 0.25 + 0.75 * spaceForSolutionPanel.max.y);
        spaceForSolutionPanel.max.x = widthOfSolutionExplorer;

        box2i spaceForOutputPanel = availableSpace;
        spaceForOutputPanel.min.y = spaceForSolutionPanel.max.y;
        spaceForOutputPanel.max.x = widthOfSolutionExplorer;

        child(2).reflow(spaceForSolutionPanel);

        child(1).reflow(spaceForOutputPanel);


        availableSpace.min.x = widthOfSolutionExplorer;
        child(0).reflow(availableSpace);
    }
}



