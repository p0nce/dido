module dido.selection;

import dido.buffer;
import dido.bufferiterator;


struct Selection
{
    BufferIterator anchor; // selection start
    BufferIterator edge;   // blinking cursor

    this(BufferIterator bothEnds) pure nothrow
    {
        anchor = bothEnds;
        edge = bothEnds;
    }

    this(BufferIterator anchor_, BufferIterator edge_) pure nothrow
    {
        edge = edge_;
        anchor = anchor_;
        assert(anchor.buffer is edge.buffer);
    }

    // start == stop => no selected area

    bool hasSelectedArea() pure const nothrow
    {
        return anchor != edge;
    }
/*
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
    }*/

    // Returns a sleection with the anchor at the left and the edge at the right
    Selection sorted() pure nothrow
    {
        if (anchor <= edge)
            return this;
        else 
            return Selection(edge, anchor);
    }
}

class SelectionSet
{
    Selection[] selections;

    this(Buffer buffer)
    {
        // always have a cursor
        selections ~= Selection(BufferIterator(buffer, Cursor(0, 0)));
    }

    this(Selection[] savedSelections)
    {
        selections = savedSelections;
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
        //import std.algorithm;
        //sort!("a < b", SwapStrategy.stable)(selections);
    }

    void keepOnlyFirst()
    {
        selections = selections[0..1];
    }    
}