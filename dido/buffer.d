module dido.buffer;


import std.file;
import std.string;
import std.conv;

// text buffers

final class Buffer
{
    this()
    {
    }

    void loadFromFile(string path)
    {
        string wholeFile = readText(path);
        dstring wholeFileUTF32 = to!dstring( wholeFile );
        lines = splitLines!(dstring)( wholeFileUTF32 );
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
