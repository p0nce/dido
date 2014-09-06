module dido.bufferiterator;

import dido.buffer;
import dido.selection;


struct Cursor
{
public:
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


struct BufferIterator
{
private:
    Buffer _buffer = null;
    Cursor _cursor = Cursor(0, 0);
public:    

    this(Buffer buffer, Cursor cursor)
    {
        _buffer = buffer;
        _cursor = cursor;
        assert(_buffer !is null);
    }    

    inout(Cursor) cursor() pure inout nothrow
    {
        return _cursor;
    }

    inout(Buffer) buffer() pure inout nothrow
    {
        return _buffer;
    }


    bool opEquals(ref const(BufferIterator) other) pure const nothrow
    {
        assert(_buffer is other._buffer);
        return _cursor == other._cursor;
    }

    BufferIterator opUnary(string op)() if (op == "++")
    {
        _cursor.column += 1;
        if (_cursor.column >= _buffer.lineLength(cursor.line))
        {
            if (_cursor.line + 1 < _buffer.numLines())
            {
                _cursor.line++;
                _cursor.column = 0;
            }
            else
            {
                _cursor.column = _buffer.lineLength(_buffer.numLines() - 1);
                assert(_cursor.column > 0);
            }
        }
        assert(isValid());
        return this;
    }

    BufferIterator opUnary(string op)() if (op == "--")
    {
        assert(_buffer !is null);
        _cursor.column -= 1;
        if (_cursor.column < 0)
        {
            if (_cursor.line > 0)
            {
                _cursor.line--;
                _cursor.column = _buffer.lineLength(cursor.line) - 1;
            }
            else
            {
                _cursor.column = 0;
            }
        }
        assert(isValid());
        return this;
    }

    BufferIterator opOpAssign(string op)(int displacement) if (op == "+=")
    {
        while (displacement > 0)
        {
            displacement--;
            opUnary!("++")();
        }
        while (displacement < 0)
        {
            displacement++;
            opUnary!("--")();
        }
        return this;
    }

    BufferIterator opOpAssign(string op)(int displacement) if (op == "-=")
    {
        return opOpAssign!"+="(-displacement);
    }

    BufferIterator opBinary(string op)(int displacement) if (op == "+")
    {
        BufferIterator result = this;
        result += displacement;
        return result;
    }

    BufferIterator opBinary(op)(int displacement) if (op == "-")
    {
        BufferIterator result = this;
        result -= displacement;
        return result;
    }

    int opCmp(ref const(BufferIterator) other) pure const nothrow
    {
        return cursor.opCmp(other._cursor);
    }

    dchar read() pure inout nothrow
    {
        assert(isValid());
        return buffer.line(cursor.line)[cursor.column];
    }

    bool isValid() pure inout nothrow
    {
        if (cursor.line < 0) 
            return false;
        if (cursor.line >= buffer.numLines())
            return false;
        if (cursor.column < 0)
            return false;

        // On last line, it is legal to have the cursor at the end of the line
        int lineLength = buffer.lineLength(cursor.line);
        if (cursor.column >= lineLength)
        {
            if ( (cursor.line == buffer.numLines() - 1) && cursor.column == lineLength)
                return true;
            else
                return false;
        }
        return true;
    }

}
