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

    bool overlaps(Selection other)
    {
        Selection tsorted = this.sorted();
        Selection osorted = other.sorted();
        if (osorted.anchor < tsorted.edge && osorted.edge >= tsorted.anchor)
            return true;
        if (tsorted.anchor < osorted.edge && tsorted.edge >= osorted.anchor)
            return true;
        return false;
    }

    int opCmp(ref Selection other) pure nothrow
    {
        Selection tsorted = this.sorted();
        Selection osorted = other.sorted();
        if (tsorted.anchor.cursor.line != osorted.anchor.cursor.line)
            return tsorted.anchor.cursor.line - osorted.anchor.cursor.line;
        if (tsorted.anchor.cursor.column != osorted.anchor.cursor.column)
            return tsorted.anchor.cursor.column - osorted.anchor.cursor.column;

        if (tsorted.edge.cursor.line != osorted.edge.cursor.line)
            return tsorted.edge.cursor.line - osorted.edge.cursor.line;
        if (tsorted.edge.cursor.column != osorted.edge.cursor.column)
            return tsorted.edge.cursor.column - osorted.edge.cursor.column;
        return 0;
    }

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
    Selection[] selections; // sorted by date

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

    void normalize()
    {
        // sort selections
        import std.algorithm;
        sort!("a < b", SwapStrategy.stable)(selections);


    }

    void keepOnlyFirst()
    {
        selections = selections[0..1];
    }

    invariant()
    {
        assert(selections.length >= 1);
    }
}