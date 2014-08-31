module dido.buffer;


import std.file;
import std.string;
import std.array;
import std.conv;

import dido.selection;
import dido.buffercommand;


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

    inout(dstring) line(int lineIndex) pure inout nothrow
    {
        return lines[lineIndex];
    }

   /* ref dstring line(int lineIndex)
    {
        return lines[lineIndex];
    }*/

    void undo()
    {
        assert(_historyIndex > 0);
        // TODO
    }

    void redo()
    {
        assert(_historyIndex < _history.length);
        applyCommand(_history[_historyIndex]);
        _historyIndex++;
    }

    void enqueueBarrier()
    {
        pushCommand(barrierCommand());
        redo();
    }

    void enqueueEdit(Selection selection, dstring newContent)
    {
        dstring oldContent = getSelectionContent(selection);
        BufferCommand command = BufferCommand(BufferCommandType.CHANGE_CHARS, selection, oldContent, newContent);
        pushCommand(command);
        redo();
    }    

private:
    dstring[] lines;
    int _historyIndex; // where we are in history
    BufferCommand[] _history;

    void pushCommand(BufferCommand command)
    {
        // strip previous history, add command
        _history = _history[0.._historyIndex] ~ command;
    }

    // If we find \n in a line, split it
    // Then: if a line doesn't end with \n, merge with next
    void normalizeLineEndings()
    {   
        size_t currentLine = 0;        
        while (currentLine < lines.length)
        {            
            dstring thisLine = lines[currentLine];
            int idx = thisLine.indexOf('\n');

            if (idx != -1 && idx + 1 != thisLine.length) // found a \n not in last position
            {
                lines.insertInPlace(currentLine, thisLine[0..idx+1].idup); // copy sub-part including \n to a new line
                lines[currentLine + 1] = lines[currentLine + 1][idx+1..$]; // next line becomes everything after the \n
            }

            currentLine++;
        }

        // make sure every line end with \n
        currentLine = 0;        
        while (currentLine + 1 < lines.length)
        {
            if (lines[currentLine].length == 0 || lines[currentLine][$-1] != '\n')
            {
                // merge two lines
                lines[currentLine] = lines[currentLine] ~ lines[currentLine + 1];
                lines = lines[0..$-1];
            }            
            else
                currentLine++;
        }
    }

    // replace a Selection content by a new content
    void replaceSelectionContent(Selection selection, dstring content)
    {
        Selection sel = selection.sorted();

        if (sel.start.line == sel.stop.line)
        {
            assert(sel.start.column <= sel.stop.column);
            replaceInPlace(lines[sel.start.line], sel.start.column, sel.stop.column, content);
        }
        else
        {
            // multi-line case
            assert(sel.stop.line > sel.start.line);

            replaceInPlace(lines[sel.start.line], sel.start.column, lines[sel.start.line].length, content);
            dstring result = lines[sel.start.line][sel.start.column..$];
            for (int line = sel.start.line + 1; line <= sel.stop.line - 1; ++line)
                lines[line] = ""d;

            replaceInPlace(lines[sel.stop.line], 0, sel.stop.column, ""d);
        }
        normalizeLineEndings();
    }

    // Gets content of a selection
    dstring getSelectionContent(Selection selection)
    {
        Selection sel = selection.sorted();

        if (sel.start.line == sel.stop.line)
        {
            assert(sel.start.column <= sel.stop.column);
            return lines[sel.start.line][sel.start.column .. sel.stop.column + 1];
        }
        else
        {
            // multi-line case
            assert(sel.stop.line > sel.start.line);

            dstring result = lines[sel.start.line][sel.start.column..$];
            for (int line = sel.start.line + 1; line <= sel.stop.line - 1; ++line)
                result ~= lines[line];
            result ~= lines[sel.stop.line][0..sel.stop.column];
            return result;
        }        
    }

    void applyCommand(BufferCommand command)
    {
        final switch(command.type) with (BufferCommandType)
        {
            case CHANGE_CHARS:
                replaceSelectionContent(command.sel, command.newContent);
                break;

            case BARRIER: 
                // do nothing
                break;
        }
    }
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

    void insertChar(dchar ch)
    {
        _selectionSet.replaceSelectionsBy(_buffer, ""d ~ ch);
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
