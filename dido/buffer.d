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
private:
    string _filepath;    
    SelectionSet _selectionSet;
    dstring[] lines;
    int _historyIndex; // where we are in history
    BufferCommand[] _history;

public:

    // create new
    this()
    {
        lines = ["\n"d];
        _selectionSet = new SelectionSet();
        _filepath = null;
    }

    this(string filepath)
    {
        loadFromFile(filepath);
        _selectionSet = new SelectionSet();
        _filepath = filepath;
    }   

    // load file in buffer, non-conforming utf-8 is lost
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

    int lineLength(int lineIndex) pure const nothrow
    {
        return lines[lineIndex].length;
    }

    inout(dstring) line(int lineIndex) pure inout nothrow
    {
        return lines[lineIndex];
    }

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

    bool isBoundToFileName()
    {
        return _filepath !is null;
    }

    void moveSelectionHorizontal(int dx, bool shift)
    {        
        foreach(ref sel; _selectionSet.selections)
        {
            Cursor* cursor = shift ? &sel.stop : &sel.start;
            cursor.column += dx;

            while (cursor.column < 0 && cursor.line > 0)
            {
                cursor.line -= 1;
                cursor.column += lines[cursor.line].length;                
            }
            if (cursor.column < 0)
                cursor.column = 0;

            while (cursor.column >= lineLength(cursor.line) && cursor.line + 1 < numLines())
            {
                cursor.column -= lines[cursor.line].length;
                cursor.line += 1;                
            }

            if (cursor.column >= lineLength(cursor.line))
                cursor.column = cast(int)(lines[cursor.line].length) - 1;

            if (!shift)            
                sel.stop = sel.start;
        }
        _selectionSet.normalize(this);        
    }

    void moveSelectionVertical(int dy, bool shift)
    {        
        foreach(ref sel; _selectionSet.selections)
        {
            Cursor* cursor = shift ? &sel.stop : &sel.start;
            cursor.line += dy;

            if (!shift)
                sel.stop = sel.start;
        }
        _selectionSet.normalize(this);
    }

    void moveToLineBegin(bool shift)
    {        
        foreach(ref sel; _selectionSet.selections)
        {
            Cursor* cursor = shift ? &sel.stop : &sel.start;
            cursor.column = 0;

            if (!shift)
                sel.stop = sel.start;
        }       

        _selectionSet.normalize(this);
    }

    void moveToLineEnd(bool shift)
    {
        foreach(ref sel; _selectionSet.selections)
        {
            Cursor* cursor = shift ? &sel.stop : &sel.start;
            cursor.column = lineLength(cursor.line) - 1;

            if (!shift)
                sel.stop = sel.start;
        }

        _selectionSet.normalize(this);
    }

    inout(SelectionSet) selectionSet() inout
    {
        return _selectionSet;
    }

    void insertChar(dchar ch)
    {
        dstring content = ""d ~ ch;
        enqueueBarrier();

        foreach(ref sel; _selectionSet.selections)
            enqueueEdit(sel, content);
    }

    string filePath()
    {
        if (_filepath is null)
            return "Untitled";
        else
            return _filepath;
    }

private:
    
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

