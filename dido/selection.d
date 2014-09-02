module dido.selection;

import dido.buffer;

struct Cursor
{
    int line = 0;
    int column = 0;

    int opCmp(ref const(Cursor) other) pure const nothrow
    {
        if (line != other.line)
            return line - other.line;
        if (column != other.column)
            return column - other.column;
        return 0;
    }
}

struct Selection
{
    Cursor start = Cursor(0, 0);
    Cursor stop = Cursor(0, 0);

    this(int line, int column) pure nothrow
    {
        start.line = line;
        start.column = column;
        stop = start;
    }

    this(Cursor start_, Cursor stop_) pure nothrow
    {
        start = start_;
        stop = stop_;
    }

    // start == stop => no selected area

    bool hasSelectedArea() pure const nothrow
    {
        return start != stop;
    }

    int opCmp(ref const(Selection) other) pure const nothrow
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

    Selection sorted() pure const nothrow
    {
        if (start <= stop)
            return this;
        else 
            return Selection(stop, start);
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

    void normalize(Buffer buffer)
    {
        foreach(ref sel; selections)
        {
            if (sel.start.line >= buffer.numLines())
                sel.start.line = buffer.numLines() - 1;

            if (sel.start.line < 0)
                sel.start.line = 0;

            if (sel.start.column >= buffer.lineLength(sel.start.line))
                sel.start.column = buffer.lineLength(sel.start.line) - 1;

            if (sel.start.column < 0)
                sel.start.column = 0;

            if (sel.stop.line >= buffer.numLines())
                sel.stop.line = buffer.numLines() - 1;

            if (sel.stop.line < 0)
                sel.stop.line = 0;

            if (sel.stop.column >= buffer.lineLength(sel.stop.line))
                sel.stop.column = buffer.lineLength(sel.stop.line) - 1;

            if (sel.stop.column < 0)
                sel.stop.column = 0;
        }        
    }   
}
