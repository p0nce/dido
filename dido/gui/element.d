module dido.gui.element;

public import dido.gui.context;

class UIElement
{
public:

    this(UIContext context)
    {
        _context = context;
    }

    final void render()
    {
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

    box2i position()
    {
        return _position;
    }

    ref UIElement[] children()
    {
        return _children;
    }

    Font font()
    {
        return _context.font;
    }

    int charWidth()
    {
        return _context.font.charWidth();
    }

    int charHeight()
    {
        return _context.font.charHeight();
    }

    UIElement child(int n)
    {
        return _children[n];
    }

    void addChild(UIElement element)
    {
        _children ~= element;
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

private:
    UIContext _context;    

    void setViewportToElement()
    {
        _context.renderer.setViewport(_position.min.x, _position.min.y, _position.width, _position.height);
    }
}
