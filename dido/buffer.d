module dido.buffer;


import std.file;
import std.string;
import std.conv;

// text buffers

class Buffer
{
    this()
    {
    }

    void loadFromFile(string path)
    {
        lines = splitLines!(dstring)( cast(dstring)( readText(path) ) );
    }

    void saveToFile(string path)
    {
        ubyte[] result;
        foreach(ref dstring line; lines)
        {
            result ~= cast(ubyte[])( to!string(line) );
            result ~= 0x10;
        }
        std.file.write(path, result);
    }

    dstring[] lines;
}
