module dido.panel.solutionpanel;

import std.path : baseName;

import dido.project;
import dido.buffer.buffer;
import dido.gui;

class SolutionPanel : UIElement
{
public:

    this(UIContext context, Project[] projects)
    {
        super(context);
        _cameraY = 0;
        _projects = projects;
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;        
    }

    override void preRender(SDL2Renderer renderer)
    {

        int itemSpace = font.charHeight() + 12;
        int marginX = 16;
        int marginY = 16;

        foreach(int iproject, project; _projects)
        {
            int px = marginX;
            int py = marginY;
            //int width = 
            //int height = iproject;

            
        }
        
/*        for(int i = 0; i < cast(int)_buffers.length; ++i)
        {   
            renderer.setColor(25, 25, 25, 255);
            int rectMargin = 4;
            renderer.fillRect(marginX - rectMargin, marginY - rectMargin + i * itemSpace, _position.width - 2 * (marginX - rectMargin), itemSpace - 4);
        }

        for(int i = 0; i < cast(int)_buffers.length; ++i)
        {
            if (i == _bufferSelect)
                font.setColor(255, 255, 255, 255);
            else
                font.setColor(200, 200, 200, 255);
            font.renderString(_prettyName[i], marginX, marginY + i * itemSpace);
        }
        */
    }

    void updateState(int projectSelect)
    {
        /*_items.

        _projects = projects;*/
        _projectSelect = projectSelect;
    }


private:
    string[] _prettyName;
    Project[] _projects;
    int _projectSelect;
    int _cameraY;

    ProjectItemPanel[] _items;
}

class ProjectItemPanel : UIElement
{
    Project _project;

    this(UIContext context, Project project)
    {
        super(context);
        _project = project;
    }
}