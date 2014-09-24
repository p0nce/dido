module dido.gui.element;

public import dido.gui.context;

class UIElement
{
public:

    this(UIContext context)
    {
        _context = context;
    }

    void close()
    {
        foreach(child; children)
            child.close();
    }

    final void render()
    {
        if (!_visible)
            return;

        setViewportToElement();
        preRender(_context.renderer);
        foreach(ref child; children)
            child.render();
        setViewportToElement();
        postRender(_context.renderer);
    }

    /// Meant to be overriden for custom behaviour.
    void reflow(box2i availableSpace)
    {
        // default: span the entire available area, and do the same for children
        _position = availableSpace;

        foreach(ref child; children)
            child.reflow(availableSpace);
    }

    final box2i position()
    {
        return _position;
    }

    final ref UIElement[] children()
    {
        return _children;
    }

    final Font font()
    {
        return _context.font;
    }

    final int charWidth() pure const nothrow
    {
        return _context.font.charWidth();
    }

    final int charHeight() pure const nothrow
    {
        return _context.font.charHeight();
    }

    final UIElement child(int n)
    {
        return _children[n];
    }

    final void addChild(UIElement element)
    {
        _children ~= element;
    }

    // This function is meant to be overriden.
    // It should return true if the click is handled.
    bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        return false;
    }

    // This function is meant to be overriden.
    // It should return true if the wheel is handled.
    bool onMouseWheel(int x, int y, int wheelDeltaX, int wheelDeltaY)
    {
        return false;
    }

    // Called when mouse move over this Element.
    void onMouseMove(int x, int y, int dx, int dy)
    {
    }

    // Called when mouse enter this Element.
    void onMouseEnter()
    {
    }

    // Called when mouse enter this Element.
    void onMouseExit()
    {
    }

    // to be called when the mouse clicked
    final bool mouseClick(int x, int y, int button, bool isDoubleClick)
    {
        foreach(child; _children)
        {
            if (child.mouseClick(x, y, button, isDoubleClick))
                return true;
        }

        if (_position.contains(vec2i(x, y)))
        {
            if(onMouseClick(x - _position.min.x, y - _position.min.y, button, isDoubleClick))
                return true;
        }

        return false;
    }

    // to be called when the mouse clicked
    final bool mouseWheel(int x, int y, int wheelDeltaX, int wheelDeltaY)
    {
        foreach(child; _children)
        {
            if (child.mouseWheel(x, y, wheelDeltaX, wheelDeltaY))
                return true;
        }

        if (_position.contains(vec2i(x, y)))
        {
            if (onMouseWheel(x - _position.min.x, y - _position.min.y, wheelDeltaX, wheelDeltaY))
                return true;
        }

        return false;
    }

    // to be called when the mouse moved
    final void mouseMove(int x, int y, int dx, int dy)
    {
        foreach(child; _children)
        {
            child.mouseMove(x, y, dx, dy);
        }
        
        if (_position.contains(vec2i(x, y)))
        {
            if (!_mouseOver)
                onMouseEnter();
            onMouseMove(x - _position.min.x, y - _position.min.y, dx, dy);
            _mouseOver = true;
        }
        else
        {
            if (_mouseOver)
                onMouseExit();
            _mouseOver = false;
        }
    }

    final UIContext context()
    {
        return _context;
    }

    final bool isVisible()
    {
        return _visible;
    }

    final void setVisible(bool visible)
    {
        _visible = visible;
    }

protected:

    /// Render this element before children.
    /// Meant to be overriden.
    void preRender(SDL2Renderer renderer)
    {
       // defaults to nothing        
    }

    /// Render this element after children elements.
    /// Meant to be overriden.
    void postRender(SDL2Renderer renderer)
    {
        // defaults to nothing
    }

    box2i _position;

    UIElement[] _children;

    bool _visible = true;


    final bool isMouseOver() pure const nothrow
    {
        return _mouseOver;
    }

private:
    UIContext _context;

    bool _mouseOver = false;

    final void setViewportToElement()
    {
        _context.renderer.setViewport(_position.min.x, _position.min.y, _position.width, _position.height);
    }    
}
