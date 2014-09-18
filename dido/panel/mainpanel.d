module dido.panel.mainpanel;

import dido.panel.panel;

class MainPanel : Panel
{
public:
    override void reflow(box2i availableSpace, int charWidth, int charHeight)
    {
        _position = availableSpace;

        // reflow horizontal bars first
        menuPanel.reflow(availableSpace, charWidth, charHeight);
        availableSpace.min.y = menuPanel.position.max.y;

        cmdlinePanel.reflow(availableSpace, charWidth, charHeight);
        availableSpace.max.y = cmdlinePanel.position.min.y;

        solutionPanel.reflow(availableSpace, charWidth, charHeight);
        availableSpace.min.x = solutionPanel.position.max.x;

        textArea.reflow(availableSpace, charWidth, charHeight);
    }

    override void render(SDL2Renderer renderer)
    {
        renderer.setViewportFull();

        textArea.render(renderer);
        solutionPanel.render(renderer);
        menuPanel.render(renderer);
        cmdlinePanel.render(renderer);
    }

    Panel textArea;
    Panel solutionPanel;
    Panel menuPanel;
    Panel cmdlinePanel;
}
