module dido.buffer;


import std.file;
import std.string;
import std.conv;

struct Cursor
{
    union
    {
        struct
        {
            int line;
            int column;
        }
        ulong as64b;
    }
}

// text buffers

class Buffer
{
public:
    this()
    {
    }

    final void loadFromFile(string path)
    {
        string wholeFile = readText(path);
        dstring wholeFileUTF32 = to!dstring(wholeFile);
        lines = splitLines!(dstring)( wholeFileUTF32 );
    }

    final void saveToFile(string path)
    {
        ubyte[] result;
        foreach(ref dstring line; lines)
        {
            result ~= cast(ubyte[])( to!string(line) );

            version(Windows)
                result ~= 0x0D;

            result ~= 0x0A;
        }
        std.file.write(path, result);
    }

    bool isValidLine(int lineIndex) pure const nothrow
    {
        return ( 0 <= lineIndex && lineIndex < lines.length ); 
    }

    int numLines() pure const nothrow
    {
        return cast(int)(lines.length);
    }

    int lastColumn(int lineIndex) pure const nothrow
    {
        return lines.length;
    }

    dstring line(int lineIndex) pure const nothrow
    {
        return lines[lineIndex];
    }

private:
    dstring[] lines;
}

class CursorSet
{
    Cursor[] cursors;

    this()
    {
        // always have a cursor
        cursors ~= Cursor(0, 0);
    }

    void removeDuplicate()
    {
        import std.algorithm;
        import std.array;
        cursors = cursors.uniq.array;
    }

    void sortCursors()
    {
        // sort cursors
        import std.algorithm;
        sort!("a.as64b < b.as64b", SwapStrategy.stable)(cursors);
    }

    void keepOnlyFirst()
    {
        cursors = cursors[0..1];
    }
}

// A buffer + cursors
class CursorBuffer
{

public:

    Buffer buffer;
    alias buffer this;

    this()
    {
        buffer = new Buffer();
        cursors = new CursorSet();
    }

    CursorSet cursors;
private:

}
