module dido.panel.textarea;

import std.conv : to;
import std.algorithm : min, max;

import gfm.sdl2;
import gfm.math.vector;

import dido.buffer.selection;
import dido.gui;
import dido.buffer.buffer;
import dido.buffer.bufferiterator;

class TextArea : UIElement
{
public:

    this(UIContext context, int marginEditor, bool haveLineNumbers, bool hasScrollbars)
    {
        super(context);

        _marginEditor = marginEditor;

        if (hasScrollbars)
        {
            addChild(new VertScrollBar(context, 9, 4, true));
            verticalScrollbar = cast(ScrollBar) child(0);

            addChild(new HorzScrollBar(context, 9, 4, false));
            horizontalScrollbar = cast(ScrollBar) child(1);
        }

        if (haveLineNumbers)
        {
            lineNumberArea = new LineNumberArea(context);
            addChild(lineNumberArea);
        }

        _editCursor = new SDL2Cursor(context.sdl2, SDL_SYSTEM_CURSOR_IBEAM);
        _previousCursor = SDL2Cursor.getCurrent(context.sdl2);
    }

    override void close()
    {
        _editCursor.close();
        _previousCursor.close();
        foreach(ref child; children)
            child.close();
    }

    override void reflow(box2i availableSpace)
    {
        if (lineNumberArea !is null)
        {
            lineNumberArea.reflow(availableSpace);
            availableSpace.min.x = lineNumberArea.position.max.x;
        }

        if (verticalScrollbar !is null) 
        {
            box2i availableForVert = availableSpace;
            verticalScrollbar.reflow(availableForVert);
            availableSpace.max.x = verticalScrollbar.position.min.x;
        }

        if (horizontalScrollbar !is null) 
        {
            horizontalScrollbar.reflow(availableSpace);
        }
        _position = availableSpace;
    }

    // Returns number of simultaneously visible lines
    int numVisibleLines() pure const nothrow
    {
        int result = (_position.height - 16) / charHeight;
        if (result < 1)
            result = 1;
        return result;
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(20, 19, 18, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        int editPosX = -_cameraX + _marginEditor;
        int editPosY = -_cameraY + _marginEditor;

        int firstVisibleLine = getFirstVisibleLine();
        int firstNonVisibleLine = getFirstNonVisibleLine();

        int firstVisibleColumn = getFirstVisibleColumn();
        int firstNonVisibleColumn = getFirstNonVisibleColumn();
        int longestLineLength = _buffer.getLongestLineLength();

        box2i visibleBox = box2i(0, 0, _position.width, _position.height);

        for (int i = firstVisibleLine; i < firstNonVisibleLine; ++i)
        {
            dstring line = _buffer.line(i);

            int posXInChars = 0;
            int posY = editPosY + i * charHeight;
            
            int maxCol =  min(line.length, firstNonVisibleColumn);

            // Allows to draw cursor on the very last file position
            if ( i + 1 == _buffer.numLines() )
                maxCol++;

            for(int j = firstVisibleColumn; j < maxCol; ++j)
            {
                Buffer.Hit hit = _buffer.intersectsSelection(Cursor(i, j));
                bool charIsSelected = hit.charInSelection;

                dchar ch = j < line.length ? line[j] : ' '; // last line read a little to far
                int widthOfChar = 1;
                bool drawDot = false;
                switch (ch)
                {
                    case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                        font.setColor(255, 200, 200);
                        break;

                    case '+', '-', '=', '>', '<', '^', ',', '$', '|', '&', '`', '/', '@', '.', '"', '[', ']', '?', ':', '\'', '\\':
                        font.setColor(255, 255, 106);
                        break;

                    case '(', ')', ';':
                        font.setColor(255, 255, 150);
                        break;

                    case '{':
                        font.setColor(108, 108, 128);
                        break;

                    case '}':
                        font.setColor(108, 108, 138);
                        break;

                    case '\n':
                        ch = ' ';
                        break;

                    case '\t':
                        ch = 0x2192;
                        font.setColor(80, 60, 70);
                        int tabLength = 1;//4; not working yet
                        widthOfChar = tabLength - posXInChars % tabLength;
                        break;

                    case ' ':
                        if (charIsSelected)
                        {
                            drawDot = true;
                        }
                        break;

                    default:
                        font.setColor(250, 250, 250);
                        break;
                }
                
                int posX = editPosX + posXInChars * charWidth;
                box2i charBox = box2i(posX, posY, posX + charWidth, posY + charHeight);

                if (visibleBox.intersects(charBox))
                {
                    if (charIsSelected)
                    {
                        // draw selection background
                        renderer.setColor(43, 54, 66, 255);
                        renderer.fillRect(charBox.min.x, charBox.min.y, charBox.width, charBox.height);
                    }

                    if (drawDot)
                    {
                        renderer.setColor(131, 137, 152, 255);
                        renderer.fillRect(charBox.min.x + charBox.width/2, charBox.min.y + charBox.height/2, 1, 1);
                    }
                    else if (ch != ' ')
                        font.renderChar(ch, posX, posY);

                    if (hit.cursorThere && _drawCursors)
                    {
                        // draw cursor
                        renderer.setColor(255, 255, 255, 255);
                        renderer.fillRect(charBox.min.x, charBox.min.y, 1, charHeight - 1);
                    }
                }
                posXInChars += widthOfChar;
            }
        }

        if (lineNumberArea !is null)
        {
            lineNumberArea.setState(_buffer, _marginEditor, firstVisibleLine, firstNonVisibleLine, _cameraY);
        }

        if (verticalScrollbar !is null)
        {
            int actualRange = maxCameraY() + _position.height;
            float start = _cameraY / cast(float)(actualRange);
            float stop = (_cameraY + _position.height) / cast(float)(actualRange);
            verticalScrollbar.setProgress(start, stop);

            // annoying grey rect in scrollbar crossing
            int scrollSize = verticalScrollbar.position.width;
            renderer.setViewport(_position.min.x, _position.min.y, _position.width + scrollSize, _position.height + scrollSize);
            renderer.setColor(0x30, 0x2C, 0x2C, 255);
            renderer.fillRect(_position.width, _position.height, scrollSize, scrollSize);
        }

        if (horizontalScrollbar !is null)
        {
            int actualRange = maxCameraX() + _position.width;
            float start = _cameraX / cast(float)(actualRange);
            float stop = (_cameraX + _position.width) / cast(float)(actualRange);
            horizontalScrollbar.setProgress(start, stop);
        }
    }

    void setState(Buffer buffer, bool drawCursors)
    {
        _buffer = buffer;
        _drawCursors = drawCursors;
    }

    void clearCamera()
    {
        _cameraX = 0;
        _cameraY = 0;
    }

    void moveCamera(int dx, int dy)
    {
        if (_buffer is null)
            return;

        _cameraX += dx;
        _cameraY += dy;
        normalizeCamera();
    }

    override bool onMouseWheel(int x, int y, int wheelDeltaX, int wheelDeltaY)
    {
        moveCamera(-wheelDeltaX * 3 * charWidth, -wheelDeltaY * 3 * charHeight);
        return true;
    }

    int maxCameraX()
    {
        int maxLineLength = _buffer.getLongestLineLength();
        return max(0, maxLineLength * charWidth - _position.width);
    }

    int maxCameraY()
    {
        return _buffer.numLines() * charHeight;
    }

    void normalizeCamera()
    {
        if (_cameraX < 0)
            _cameraX = 0;

        if (_cameraX > maxCameraX())
            _cameraX = maxCameraX();

        if (_cameraY < 0)
            _cameraY = 0;

        if (_cameraY > maxCameraY())
            _cameraY = maxCameraY();
    }

    box2i cameraBox() pure const nothrow
    {
        return box2i(_cameraX, _cameraY, _cameraX + _position.width, _cameraY + _position.height);
    }

    box2i edgeBox(Selection sel)
    {
        return box2i(_cameraX, _cameraY, _cameraX + _position.width, _cameraY + _position.height);
    }

    void ensureOneVisibleSelection()
    {
        double minDistance = double.infinity;
        Selection bestSel;
        SelectionSet selset = _buffer.selectionSet();
        foreach(Selection sel; selset.selections)
        {
            double distance = selectionDistance(sel);
            if (distance < minDistance)
            {
                bestSel = sel;
                minDistance = distance;
            }
        }
        ensureSelectionVisible(bestSel);
    }

    override void onMouseEnter()
    {
        _editCursor.setCurrent();
    }

    override void onMouseExit()
    {
        _previousCursor.setCurrent();
    }

    override bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        if (_buffer is null)
            return false;

        // implement click on buffer and CTRL + click
        if (button == SDL_BUTTON_LEFT || button == SDL_BUTTON_RIGHT)
        {
            bool ctrl = context.sdl2.keyboard.isPressed(SDLK_LCTRL) || context.sdl2.keyboard.isPressed(SDLK_RCTRL);

            int line = (y - _marginEditor + _cameraY) / charHeight;
            int column = (x - _marginEditor + _cameraX + (charWidth / 2)) / charWidth;

            _buffer.addNewSelection(line, column, ctrl);
            return true;
        }

        return false;
    }

    override void onMouseDrag(int x, int y, int dx, int dy)
    {
        if (_buffer is null)
            return;

        // implement drag selection        
        {
            // TODO, need selection timestamps, or some way to have a selection outside of Buffer (better)

        }
    }

    class VertScrollBar : ScrollBar
    {
    public:
        this(UIContext context, int widthOfFocusBar, int padding, bool vertical)
        {
            super(context, widthOfFocusBar, padding, vertical);
        }

        override void onScrollChangeMouse(float newProgressStart)
        {
            int actualRange = maxCameraY() + _position.height;
            _cameraY = cast(int)(0.5f + newProgressStart * actualRange);
            normalizeCamera();
        }
    }

    class HorzScrollBar : ScrollBar
    {
    public:
        this(UIContext context, int widthOfFocusBar, int padding, bool vertical)
        {
            super(context, widthOfFocusBar, padding, vertical);
        }

        override void onScrollChangeMouse(float newProgressStart)
        {
            int actualRange = maxCameraX() + _position.width;
            _cameraX = cast(int)(0.5f + newProgressStart * actualRange);
            normalizeCamera();
        }
    }

private:
    int _cameraX = 0;
    int _cameraY = 0;
    Buffer _buffer;    
    bool _drawCursors;

    SDL2Cursor _editCursor;
    SDL2Cursor _previousCursor;

    int _marginEditor;

    LineNumberArea lineNumberArea;
    ScrollBar verticalScrollbar;
    ScrollBar horizontalScrollbar;

    int getFirstVisibleLine() pure const nothrow
    {
        return max(0, _cameraY / charHeight - 1);
    }

    int getFirstVisibleColumn() pure const nothrow
    {
        return max(0, _cameraX / charWidth - 1);
    }

    int getFirstNonVisibleLine() pure const nothrow
    {
        return min(_buffer.numLines(), 1 + (_cameraY + _position.height + charHeight - 1) / charHeight);
    }

    int getFirstNonVisibleColumn() pure const nothrow
    {
        return min(_buffer.getLongestLineLength(), 1 + (_cameraX + _position.width + charWidth - 1) / charWidth);
    }

    box2i getEdgeBox(Selection selection)
    {
        vec2i edgePos = vec2i(selection.edge.cursor.column * charWidth + _marginEditor, 
                              selection.edge.cursor.line * charHeight + _marginEditor);
        return box2i(edgePos.x, edgePos.y, edgePos.x + charWidth, edgePos.y + charHeight);
    }

    // 0 if visible
    // more if not visible
    double selectionDistance(Selection selection)
    {
        return cameraBox().distance(getEdgeBox(selection));
    }

    void ensureSelectionVisible(Selection selection)
    {
        int scrollMargin = _marginEditor;
        box2i edgeBox = getEdgeBox(selection);
        box2i camBox = cameraBox();
        if (edgeBox.min.x < camBox.min.x + scrollMargin)
            _cameraX += (edgeBox.min.x - camBox.min.x - scrollMargin);
        
        if (edgeBox.max.x > camBox.max.x - scrollMargin)
            _cameraX += (edgeBox.max.x - camBox.max.x + scrollMargin);

        if (edgeBox.min.y < camBox.min.y + scrollMargin)
            _cameraY += (edgeBox.min.y - camBox.min.y - scrollMargin);
        if (edgeBox.max.y > camBox.max.y - scrollMargin)
            _cameraY += (edgeBox.max.y - camBox.max.y + scrollMargin);
        normalizeCamera();
    }

    void renderSelectionForeground(SDL2Renderer renderer, int offsetX, int offsetY, Selection selection, bool drawCursors)
    {
        Selection sorted = selection.sorted();

        // don't draw invisible selections
        if (sorted.edge.cursor.line < getFirstVisibleLine())
            return;

        if (sorted.anchor.cursor.line >= getFirstNonVisibleLine())
            return;

        
        if (drawCursors)
        {
            int startX = offsetX + selection.edge.cursor.column * charWidth;
            int startY = offsetY + selection.edge.cursor.line * charHeight;

            renderer.setColor(255, 255, 255, 255);
            renderer.fillRect(startX, startY, 1, charHeight - 1);
        }
    }
}


class LineNumberArea : UIElement
{
public:

    this(UIContext context)
    {
        super(context);
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.max.x = _position.min.x + 6 * charWidth;
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(28, 28, 28, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        for (int i = _firstVisibleLine; i < _firstNonVisibleLine; ++i)
        {
            dstring lineNumber = to!dstring(i + 1) ~ " ";
            while (lineNumber.length < 6)
            {
                lineNumber = " "d ~ lineNumber;
            }

            font.setColor(49, 97, 107, 160);
            font.renderString(lineNumber,  0,  0 -_cameraY + _marginEditor + i * charHeight);
        }
    }

    void setState(Buffer buffer, int marginEditor, int firstVisibleLine, int firstNonVisibleLine, int cameraY)
    {
        _buffer = buffer;
        _cameraY = cameraY;
        _firstVisibleLine = firstVisibleLine;
        _firstNonVisibleLine = firstNonVisibleLine;
        _marginEditor = marginEditor;
    }

private:
    Buffer _buffer;
    int _cameraY;
    int _marginEditor;
    int _firstVisibleLine;
    int _firstNonVisibleLine;
}


