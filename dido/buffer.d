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

    void initializeNew()
    {
        lines = ["\n"d];
    }

    // load file in buffer, non-conrofming utf-8 is lost
    final void loadFromFile(string path)
    {
        string wholeFile = readText(path);
        dstring wholeFileUTF32 = to!dstring(wholeFile);
        lines = splitLines!(dstring)( wholeFileUTF32 );

        foreach(ref dstring line; lines)
        {
            line ~= 0x0A;
        }
    }

    // save file using OS end-of-lines
    final void saveToFile(string path)
    {
        ubyte[] result;
        foreach(ref dstring dline; lines)
        {
            string line = to!string(dline);

            version(Windows)
            {
                if (line.length > 0 && line[$-1] == '\n')
                {
                    line = line[0..$-1] ~ "\r\n";
                }

                result ~= line;
            }
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


// A buffer + cursors + optional filename
class SelectionBuffer
{
public:

    alias _buffer this;
    Buffer _buffer;

    // create new
    this()
    {
        _buffer = new Buffer();
        _buffer.initializeNew();
        _selectionSet = new SelectionSet();
        _filepath = null;
    }

    this(string filepath)
    {
        _buffer = new Buffer();
        _buffer.loadFromFile(filepath);
        _selectionSet = new SelectionSet();
        _filepath = filepath;
    }

    bool isBoundToFileName()
    {
        return _filepath !is null;
    }

    void moveSelection(int dx, int dy)
    {
        _selectionSet.move(_buffer, dx, dy);
    }

    void moveToLineBegin()
    {
        _selectionSet.moveToLineBegin(_buffer);
    }

    void moveToLineEnd()
    {
        _selectionSet.moveToLineEnd(_buffer);
    }

    inout(SelectionSet) selectionSet() inout
    {
        return _selectionSet;
    }

    string filePath()
    {
        if (_filepath is null)
            return "Untitled";
        else
            return _filepath;
    }
    
private:
    string _filepath;    
    SelectionSet _selectionSet;
}
