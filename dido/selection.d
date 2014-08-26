module dido.selection;

import dido.buffer;

struct Cursor
{
    int line;
    int column;
}

struct Selection
{
    Cursor start;
    Cursor stop;

    this(int line, int column)
    {
        start.line = line;
        start.column= column;
        stop = start;
    }

    // start == stop => no selected area

    bool hasSelectedArea()
    {
        return start != stop;
    }

    int opCmp(ref const(Selection) other)
    {
        if (start.line != other.start.line)
            return start.line - other.start.line;
        if (start.column != other.start.column)
            return stop.column - other.start.column;

        if (stop.line != other.stop.line)
            return stop.line - other.stop.line;
        if (stop.column != other.stop.column)
            return stop.column - other.stop.column;
        return 0;
    }
}

class SelectionSet
{
    Selection[] selections;

    this()
    {
        // always have a cursor
        selections ~= Selection(0, 0);
    }

    void removeDuplicate()
    {
        import std.algorithm;
        import std.array;
        selections = selections.uniq.array;
    }

    void sortCursors()
    {
        // sort cursors
        import std.algorithm;
        sort!("a < b", SwapStrategy.stable)(selections);
    }

    void keepOnlyFirst()
    {
        selections = selections[0..1];
    }

    void move(Buffer buffer, int dx, int dy)
    {
        foreach(ref sel; selections)
        {
            sel.start.column += dx;
            sel.start.line += dy;
        }
        normalize(buffer);
    }

    void moveToLineBegin(Buffer buffer)
    {
        foreach(ref sel; selections)
        {
            sel.start.column = 0;
        }
        normalize(buffer);
    }

    void moveToLineEnd(Buffer buffer)
    {
        foreach(ref sel; selections)
        {
            sel.start.column = buffer.lastColumn(sel.start.line) - 1;
        }
        normalize(buffer);
    }


    void normalize(Buffer buffer)
    {
        foreach(ref sel; selections)
        {
            if (sel.start.line >= buffer.numLines())
                sel.start.line = buffer.numLines() - 1;

            if (sel.start.line < 0)
                sel.start.line = 0;

            if (sel.start.column >= buffer.lastColumn(sel.start.line))
                sel.start.column = buffer.lastColumn(sel.start.line) - 1;

            if (sel.start.column < 0)
                sel.start.column = 0;

            sel.stop = sel.start;
        }
        
    }
}
