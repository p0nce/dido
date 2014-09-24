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
            addChild(new ScrollBar(context, 8, 4, true));
            verticalScrollbar = cast(ScrollBar) child(0);

            addChild(new ScrollBar(context, 8, 4, false));
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
            availableForVert.max.y -= verticalScrollbar.buttonSize();
            verticalScrollbar.reflow(availableForVert);
            availableSpace.max.x = verticalScrollbar.position.min.x;
        }

        if (horizontalScrollbar !is null) 
        {
            horizontalScrollbar.reflow(availableSpace);
            availableSpace.max.y = horizontalScrollbar.position.min.y;
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
        int editPosX = -_cameraX + _marginEditor;
        int editPosY = -_cameraY + _marginEditor;

        int firstVisibleLine = getFirstVisibleLine();
        int firstNonVisibleLine = getFirstNonVisibleLine();

        int firstVisibleColumn = getFirstVisibleColumn();
        int firstNonVisibleColumn = getFirstNonVisibleColumn();
        int longestLineLength = _buffer.getLongestLineLength();

        // draw selection background
        SelectionSet selset = _buffer.selectionSet();
        foreach(Selection sel; selset.selections)
        {
            renderSelectionBackground(renderer, editPosX, editPosY, sel);
        }

        for (int i = firstVisibleLine; i < firstNonVisibleLine; ++i)
        {
            dstring line = _buffer.line(i);

            int posXInChars = 0;
            int posY = editPosY + i * charHeight;
            
            int maxCol =  min(line.length, firstNonVisibleColumn);
            for(int j = firstVisibleColumn; j < maxCol; ++j)
            {
                dchar ch = line[j];
                int widthOfChar = 1;
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
                        ch = ' '; //0x2193; // down arrow
                        font.setColor(40, 40, 40);
                        break;

                    case '\t':
                        ch = 0x2192;
                        font.setColor(80, 60, 70);
                        int tabLength = 1;//4; not working yet
                        widthOfChar = tabLength - posXInChars % tabLength;
                        break;

                    case ' ':
                        ch = 0x2D1;
                        font.setColor(60, 60, 70);
                        break;

                    default:
                        font.setColor(250, 250, 250);
                        break;
                }

                box2i visibleBox = box2i(0, 0, _position.width, _position.height);
                int posX = editPosX + posXInChars * charWidth;
                box2i charBox = box2i(posX, posY, posX + charWidth, posY + charHeight);
                if (visibleBox.intersects(charBox))
                    font.renderChar(ch, posX, posY);
                posXInChars += widthOfChar;
            }
        }

        // draw selection foreground
        foreach(Selection sel; selset.selections)
        {
            renderSelectionForeground(renderer, editPosX, editPosY, sel, _drawCursors);
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
            verticalScrollbar.setState(start, stop);
        }

        if (horizontalScrollbar !is null)
        {
            int actualRange = maxCameraX() + 3 * charWidth;
            float start = _cameraX / cast(float)(actualRange);
            float stop = (_cameraX + _position.width) / cast(float)(actualRange);
            horizontalScrollbar.setState(start, stop);
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
        if (maxLineLength == 0)
            maxLineLength = 1;
        return maxLineLength * charWidth; // TODO maintain length of longest line in Buffer
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

    void renderSelectionBackground(SDL2Renderer renderer, int offsetX, int offsetY, Selection selection)
    {
        Selection sorted = selection.sorted();

        // don't draw invisible selections
        if (sorted.edge.cursor.line < getFirstVisibleLine())
            return;

        if (sorted.anchor.cursor.line >= getFirstNonVisibleLine())
            return;

        
        // draw the selection part
        BufferIterator it = sorted.anchor;
        while (it < sorted.edge)
        {
            int startX = offsetX + it.cursor.column * charWidth;
            int startY = offsetY + it.cursor.line * charHeight;
            renderer.setColor(43, 54, 66, 255);
            renderer.fillRect(startX, startY, charWidth, charHeight);
            ++it;
        }
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
