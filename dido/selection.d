module dido.selection;

import dido.buffer;
import dido.bufferiterator;


struct Selection
{
    BufferIterator start;
    BufferIterator stop;

    this(BufferIterator bothEnds) pure nothrow
    {
        start = bothEnds;
        stop = bothEnds;
    }

    this(BufferIterator start_, BufferIterator stop_) pure nothrow
    {
        start = start_;
        stop = stop_;
        assert(start.buffer is stop.buffer);
    }

    // start == stop => no selected area

    bool hasSelectedArea() pure const nothrow
    {
        return start != stop;
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

    Selection sorted() pure nothrow
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

    this(Buffer buffer)
    {
        // always have a cursor
        selections ~= Selection(BufferIterator(buffer, Cursor(0, 0)));
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