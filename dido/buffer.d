module dido.buffer;


import std.file;
import std.string;
import std.conv;

import dido.selection;


// text buffers

class Buffer
{
public:
    this()
    {
    }

    // load file in buffer, non-conrofming utf-8 is lost
    final void loadFromFile(string path)
    {
        string wholeFile = readText(path);
        dstring wholeFileUTF32 = to!dstring(wholeFile);
        lines = splitLines!(dstring)( wholeFileUTF32 );
    }

    // save file using OS end-of-lines
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
        return lines[lineIndex].length;
    }

    dstring line(int lineIndex) pure const nothrow
    {
        return lines[lineIndex];
    }

private:
    dstring[] lines;
}


// A buffer + cursors
class SelectionBuffer
{
public:
    Buffer buffer;
    alias buffer this;

    this()
    {
        buffer = new Buffer();
        selectionSet = new SelectionSet();
    }

    void moveSelection(int dx, int dy)
    {
        selectionSet.move(buffer, dx, dy);
    }

    SelectionSet selectionSet;
private:

}
