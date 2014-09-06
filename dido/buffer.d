module dido.buffer;


import std.file;
import std.string;
import std.array;
import std.conv;

import dido.selection;
import dido.buffercommand;
import dido.bufferiterator;


// text buffers

final class Buffer
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
        lines = [""d];
        _selectionSet = new SelectionSet(this);
        _filepath = null;
    }

    this(string filepath)
    {
        lines = [""d];
        loadFromFile(filepath);
        _selectionSet = new SelectionSet(this);
        _filepath = filepath;
    }   

    BufferIterator begin()
    {
        return BufferIterator(this, Cursor(0, 0));
    }

    BufferIterator end()
    {
        return BufferIterator(this, Cursor(0, 0));
    }

    // load file in buffer, non-conforming utf-8 is lost
    void loadFromFile(string path)
    {
        string wholeFile = readText(path);
        dstring wholeFileUTF32 = to!dstring(wholeFile);
        lines = splitLines!(dstring)( wholeFileUTF32 );

        for (int line = 0; line + 1 < cast(int)lines.length; ++line)
        {
            lines[line] ~= 0x0A;
        }
    }

    // save file using OS end-of-lines
    void saveToFile(string path)
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
        while (_historyIndex > 0)
        {
            _historyIndex--;
            if (reverseCommand(_history[_historyIndex]))
                break;
        }
    }

    void redo()
    {
        int barrierFound = 0;
        while (_historyIndex < _history.length)
        {
            if (_history[_historyIndex].type == BufferCommandType.BARRIER)
                barrierFound++;

            if (barrierFound >= 2)
                return;

            applyCommand(_history[_historyIndex]);
            _historyIndex++;
        }
    }

    bool isBoundToFileName()
    {
        return _filepath !is null;
    }

    void moveSelectionHorizontal(int dx, bool shift)
    {        
        foreach(ref sel; _selectionSet.selections)
        {
            sel.edge = sel.edge + dx;

            if (!shift)            
                sel.anchor = sel.edge;
        }
    }

    void moveSelectionVertical(int dy, bool shift)
    {        
        /*foreach(ref sel; _selectionSet.selections)
        {
            Cursor* cursor = shift ? &sel.stop : &sel.start;
            cursor.line += dy;

            if (!shift)
                sel.stop = sel.start;
        }
        _selectionSet.normalize(this);*/
    }

    void moveToLineBegin(bool shift)
    {        
      /*  foreach(ref sel; _selectionSet.selections)
        {
            BufferIterator* iterator = shift ? &sel.stop : &sel.start;
            iterator.cursor.column = 0;

            if (!shift)
                sel.stop = sel.start;
        }       

        _selectionSet.normalize(this);*/
    }

    void moveToLineEnd(bool shift)
    {
     /*   foreach(ref sel; _selectionSet.selections)
        {
            BufferIterator* iterator = shift ? &sel.stop : &sel.start;
            iterator = iterator.endOfLine();
            cursor.column = lineLength(cursor.line) - 1;

            if (!shift)
                sel.stop = sel.start;
        }

        _selectionSet.normalize(this);*/
    }

    inout(SelectionSet) selectionSet() inout
    {
        return _selectionSet;
    }

    void insertChar(dchar ch)
    {
        dstring content = ""d ~ ch;
        enqueueBarrier();
        enqueueSaveSelections();

        foreach(ref sel; _selectionSet.selections)
            sel = enqueueEdit(sel, content);
        enqueueSaveSelections();    }

    // selection with area => delete selection
    // else delete character at cursor or before cursor
    void deleteSelection(bool isBackspace)
    {
        enqueueBarrier();
        enqueueSaveSelections();

        foreach(ref sel; _selectionSet.selections)
        {
            if (sel.hasSelectedArea())
                enqueueEdit(sel, ""d);
            else
            {
                Selection selOneChar = sel.sorted;
                if (isBackspace)
                    selOneChar.anchor--;
                else
                    selOneChar.edge++;

                enqueueEdit(selOneChar, ""d);
            }
        }
        moveSelectionHorizontal(-1, false);
        enqueueSaveSelections();
    }

    string filePath()
    {
        if (_filepath is null)
            return "Untitled";
        else
            return _filepath;
    }

    invariant()
    {
        // at least one line
        assert(lines.length > 0);
        for(size_t i = 0; i < lines.length; ++i)
        {
            if( i == lines.length - 1)
            {
                if (lines[i].length > 0)
                    assert(lines[i][$-1] != '\n');
            }
            else
            {
                assert(lines[i].length > 0);
                assert(lines[i][$-1] == '\n');
            }
        }
    }

private:
    
    void pushCommand(BufferCommand command)
    {
        // strip previous history, add command
        _history = _history[0.._historyIndex] ~ command;
        _historyIndex = _history.length;
    }

    // replace a Selection content by a new content
    // returns a cursor Selection just after the newly inserted part
    Selection replaceSelectionContent(Selection selection, dstring content)
    {
        Selection sel = selection.sorted();
        erase(sel.anchor, sel.edge);
        BufferIterator after = insert(sel.anchor, content);
        return Selection(sel.anchor, after);       
    }

    // Gets content of a selection
    dstring getSelectionContent(Selection selection)
    {
        Selection sel = selection.sorted();
        dstring result;

        for (BufferIterator it = sel.anchor; it != sel.edge; ++it)
            result ~= it.read();

        return result;
    }

    BufferIterator insert(BufferIterator pos, dstring content)
    {
        foreach(dchar ch ; content)
            pos = insert(pos, ch);
        return pos;
    }

    // return an iterator after the inserted char
    BufferIterator insert(BufferIterator pos, dchar content)
    {
        assert(pos.isValid());

        if (content == '\n')
        {
            int col = pos.cursor.column;
            int line = pos.cursor.line;
            dstring thisLine = lines[line];
            lines.insertInPlace(line, thisLine[0..col].idup ~ '\n'); // copy sub-part addind a \n
            lines[line + 1] = lines[line + 1][col..$]; // next line becomes everything else
            return BufferIterator(pos.buffer, Cursor(line + 1, 0));
        }
        else
        {
            int line = pos.cursor.line;
            int column = pos.cursor.column;
            dstring oneCh = (&content)[0..1].idup;
            replaceInPlace(lines[line], column, column, oneCh);
            return BufferIterator(pos.buffer, Cursor(line, column + 1));
        }
    }

    void erase(BufferIterator pos)
    {
        dchar chErased = pos.read();
        if (chErased == '\n')
        {
            int line = pos.cursor.line;
            int column = pos.cursor.column;
            dstring newLine = lines[line][0..$-1] ~ lines[line+1];
            replaceInPlace(lines, line, line + 2, [ newLine ]);
        }
        else
        {
            int line = pos.cursor.line;
            int column = pos.cursor.column;
            replaceInPlace(lines[line], column, column + 1, ""d);
        }
    }

    void erase(BufferIterator begin, BufferIterator end)
    {
        while (begin < end)
        {
            --end;
            erase(end);            
        }     
    }

    void applyCommand(BufferCommand command)
    {
        final switch(command.type) with (BufferCommandType)
        {
            case CHANGE_CHARS:
                replaceSelectionContent(command.changeChars.oldSel, command.changeChars.newContent);
                break;

            case SAVE_SELECTIONS:
                // also restore them, useful in redo sequences
                _selectionSet.selections = command.saveSelections.selections.dup;
                break;

            case BARRIER: 
                // do nothing
                break;
        }
    }

    // returns true if it was a barrier
    bool reverseCommand(BufferCommand command)
    {
        final switch(command.type) with (BufferCommandType)
        {
            case CHANGE_CHARS:
                replaceSelectionContent(command.changeChars.newSel, command.changeChars.oldContent);
                return false;

            case SAVE_SELECTIONS:
                // restore selections
                _selectionSet.selections = command.saveSelections.selections.dup;
                return false;

            case BARRIER: 
                return true;
        }
    }

    void enqueueBarrier()
    {
        pushCommand(barrierCommand());
    }

    void enqueueSaveSelections()
    {
        pushCommand(saveSelectionsCommand(_selectionSet.selections));
    }

    Selection enqueueEdit(Selection selection, dstring newContent)
    {
        dstring oldContent = getSelectionContent(selection);
        Selection newSel = replaceSelectionContent(selection, newContent);
        BufferCommand command = saveSelectionsCommand(selection, newSel, oldContent, newContent);        
        pushCommand(command);
        return Selection(newSel.edge);
    }
}

