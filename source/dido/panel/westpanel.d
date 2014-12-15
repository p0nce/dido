module dido.panel.westpanel;

import std.path : baseName;

import dido.buffer.buffer;
import dido.gui;

import dido.panel.solutionpanel,
       dido.panel.outputpanel;

class WestPanel : UIElement
{
public:

    this(UIContext context, SolutionPanel solutionPanel, OutputPanel outputPanel)
    {
        super(context);
        addChild(solutionPanel);
        addChild(outputPanel);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;

        int margin = 2;

        box2i spaceForSolutionPanel = availableSpace;
        spaceForSolutionPanel.max.y = cast(int)(0.5 + spaceForSolutionPanel.min.y * 0.25 + 0.75 * spaceForSolutionPanel.max.y);
        box2i spaceForOutputPanel = availableSpace;
        spaceForOutputPanel.min.y = spaceForSolutionPanel.max.y;

        spaceForSolutionPanel.min.x += margin;
        spaceForSolutionPanel.max.x -= margin;
        spaceForSolutionPanel.min.y += margin;
        spaceForSolutionPanel.max.y -= margin / 2;
        
        spaceForOutputPanel.min.x += margin;
        spaceForOutputPanel.max.x -= margin;
        spaceForOutputPanel.min.y += margin / 2;

        child(0).reflow(spaceForSolutionPanel);
        child(1).reflow(spaceForOutputPanel);
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(34, 34, 34, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);
    }

private:
    SolutionPanel _solutionPanel;
    OutputPanel _outputPanel;
}
