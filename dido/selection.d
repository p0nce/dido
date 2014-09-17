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

    Selection opOpAssign(string op)(int displacement) if (op == "+")
    {
        anchor += displacement;
        edge += displacement;
        return this;
    }

    // Returns a sleection with the anchor at the left and the edge at the right
    Selection sorted() pure nothrow
    {
        if (anchor <= edge)
            return this;
        else 
            return Selection(edge, anchor);
    }

    // lenght of selection in chars
    int area()
    {
        Selection tsorted = this.sorted();
        int result = 0;
        while(tsorted.anchor < tsorted.edge)
        {
            ++tsorted.anchor;
            result += 1;
        }
        return result;
    }

    bool isValid() pure const nothrow
    {
        return anchor.isValid() && edge.isValid();
    }

    void translateByEdit(BufferIterator before, BufferIterator after)
    {
        Selection tsorted = this.sorted();
        assert(before <= tsorted.anchor);
        
        import std.stdio;
        if (before.cursor.line != after.cursor.line)
        {
            anchor.cursor.line += after.cursor.line - before.cursor.line;
            edge.cursor.line += after.cursor.line - before.cursor.line;
            writefln("Moves selection by %s lines", after.cursor.line - before.cursor.line);

            if (anchor.cursor.line == after.cursor.line)
                anchor.cursor.column = after.cursor.column;
            if (edge.cursor.line == after.cursor.line)
                edge.cursor.column = after.cursor.column;
        }

        if (before.cursor.line == anchor.cursor.line)
        {
            int dispBefore = anchor.cursor.column - before.cursor.column;
            anchor.cursor.column = after.cursor.column + dispBefore;
            writefln("Moves selection anchor to %s", anchor.cursor.column);
        }

        if (before.cursor.line == edge.cursor.line)
        {
            int dispBefore = edge.cursor.column - before.cursor.column;
            edge.cursor.column = after.cursor.column + dispBefore;
            writefln("Moves selection edge to %s", anchor.cursor.column);
        }
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

        int i = 0;
        while (i < cast(int)(selections.length) - 1)
        {
            if (selections[i].overlaps(selections[i+1]))
            {
                // merge overlapping selections
                Selection A = selections[i].sorted();
                Selection B = selections[i+1].sorted();
                BufferIterator anchor = A.anchor < B.anchor ? A.anchor : B.anchor;
                BufferIterator edge = A.edge > B.edge ? A.edge : B.edge;
                selections = selections[0..i] ~ Selection(anchor, edge) ~ selections[i+2..$];
            }
            else if (selections[i] == selections[i+1])
            {
                // drop one of two identical selections
                selections = selections[0..i] ~ selections[i+1..$];
            }
            else
                ++i;
        }
    }

    void keepOnlyFirst()
    {
        selections = selections[0..1];
        selections[0].anchor = selections[0].edge;
    }

    void keepOnlyEdge()
    {
        foreach(ref sel; selections)
            sel.anchor = sel.edge;
    }

    invariant()
    {
        assert(selections.length >= 1);
    }
}