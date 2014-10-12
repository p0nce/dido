module dido.engine;

import std.process;
import std.string;

import gfm.sdl2;

import dido.panel;
import dido.command;
import dido.buffer.buffer;
import dido.window;

// Model
class DidoEngine
{
private:
    TextArea _textArea;
    CommandLinePanel _cmdlinePanel;
    bool _commandLineMode;
    Buffer _bufferEdit; // current buffer in edit area
    Buffer[] _buffers;
    int _bufferSelect;
    Window _window;
    SDL2 _sdl2;
    bool _finished;

public:

    this(SDL2 sdl2, Window window, TextArea textArea, CommandLinePanel cmdlinePanel, string[] paths)
    {
        foreach (ref path; paths)
        {
            Buffer buf = new Buffer(path);
            _buffers ~= buf;
        }

        // create an empty buffer if no file provided
        if (_buffers.length == 0)
        {
            Buffer buf = new Buffer;
            _buffers ~= buf;
        }

        setCurrentBufferEdit(0);        
        _textArea = textArea;
        _cmdlinePanel = cmdlinePanel;
        _window = window;
        _commandLineMode = false;
        _finished = false;
        _sdl2 = sdl2;
    }

    Buffer[] buffers()
    {
        return _buffers;
    }

    bool isCommandLineMode()
    {
        return _commandLineMode;
    }

    int bufferSelect()
    {
        return _bufferSelect;
    }

    void setCurrentBufferEdit(int bufferSelect)
    {
        _bufferSelect = bufferSelect;
        _bufferEdit = _buffers[_bufferSelect];
        _bufferEdit.ensureLoaded();
    }

    Buffer currentEditBuffer()
    {
        return _bufferEdit;
    }

    bool finished()
    {
        return _finished;
    }

    Buffer currentBuffer()
    {
        if (_commandLineMode)
            return _cmdlinePanel.buffer();
        else
            return _bufferEdit;
    }

    TextArea currentTextArea()
    {
        if (_commandLineMode)
            return _cmdlinePanel.textArea();
        else
            return _textArea;
    }

    void executeCommand(Command command)
    {
        Buffer buffer = currentBuffer();
        TextArea textArea = currentTextArea();
        final switch (command.type) with (CommandType)
        {            
            case MOVE_UP:
                buffer.moveSelectionVertical(-1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_DOWN:
                buffer.moveSelectionVertical(1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_LEFT:
                buffer.moveSelectionHorizontal(-1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_RIGHT:            
                buffer.moveSelectionHorizontal(+1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_WORD_LEFT:
                buffer.moveSelectionWord(-1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_WORD_RIGHT:
                buffer.moveSelectionWord(+1, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_LINE_BEGIN:
                buffer.moveToLineBegin(command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case MOVE_LINE_END:
                buffer.moveToLineEnd(command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case TOGGLE_FULLSCREEN:
                _window.toggleFullscreen();
                textArea.ensureOneVisibleSelection();
                break;

            case ROTATE_NEXT_BUFFER:
                setCurrentBufferEdit( (_bufferSelect + 1) % _buffers.length );
                currentTextArea().clearCamera();
                currentTextArea().ensureOneVisibleSelection();
                break;

            case ROTATE_PREVIOUS_BUFFER:
                setCurrentBufferEdit( (_bufferSelect + _buffers.length - 1) % _buffers.length );
                currentTextArea().clearCamera();
                currentTextArea().ensureOneVisibleSelection();
                break;

            case PAGE_UP:
                buffer.moveSelectionVertical(-_textArea.numVisibleLines, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case PAGE_DOWN:
                buffer.moveSelectionVertical(_textArea.numVisibleLines, command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case UNDO:
                buffer.undo();
                textArea.ensureOneVisibleSelection();
                break;

            case REDO:
                buffer.redo();
                textArea.ensureOneVisibleSelection();
                break;

            case ENTER_COMMANDLINE_MODE:
                if (!_commandLineMode)
                {
                    _commandLineMode = true;
                    currentBuffer().clearContent();                    
                }
                else
                {
                    _commandLineMode = false;
                    currentBuffer().insertChar(':');
                    currentTextArea().ensureOneVisibleSelection();                    
                }
                break;

            case BACKSPACE:
                buffer.deleteSelection(true);
                textArea.ensureOneVisibleSelection();
                break;

            case DELETE:
                buffer.deleteSelection(false);
                textArea.ensureOneVisibleSelection();
                break;

            case RETURN:
                if (_commandLineMode)
                {
                    executeCommandLine(_cmdlinePanel.getCommandLine());
                    goto case ESCAPE;
                }
                else
                {
                    buffer.insertChar('\n');
                    textArea.ensureOneVisibleSelection();
                    break;
                }

            case ESCAPE:
                if (_commandLineMode)
                    _commandLineMode = false;
                else
                {
                    buffer.selectionSet().keepOnlyFirst();
                    textArea.ensureOneVisibleSelection();
                }
                break;

            case INSERT_CHAR:
                buffer.insertChar(command.ch);
                textArea.ensureOneVisibleSelection();
                break;

            case EXTEND_SELECTION_UP:
                buffer.extendSelectionVertical(-1);
                textArea.ensureOneVisibleSelection();
                break;

            case EXTEND_SELECTION_DOWN:
                buffer.extendSelectionVertical(1);
                textArea.ensureOneVisibleSelection();
                break;

            case GOTO_START_OF_BUFFER:
                buffer.moveSelectionToBufferStart(command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case GOTO_END_OF_BUFFER:
                buffer.moveSelectionToBufferEnd(command.shift);
                textArea.ensureOneVisibleSelection();
                break;

            case SELECT_ALL_BUFFER:
                buffer.selectAll();
                textArea.ensureOneVisibleSelection();
                break;

            case BUILD:
                auto dubResult = execute(["dub", "build"]);
                if (dubResult.status != 0)
                    throw new Exception(format("dub returned %s", dubResult.status));
                break;

            case RUN:
                auto dubResult = execute(["dub", "run"]);
                if (dubResult.status != 0)
                    throw new Exception(format("dub returned %s", dubResult.status));
                break;

            case SAVE:
                if (!_commandLineMode)
                    saveCurrentBuffer();
                break;

            case COPY:
                _sdl2.setClipboard(to!string(buffer.copy()));
                textArea.ensureOneVisibleSelection();
                break;

            case CUT:
                _sdl2.setClipboard(to!string(buffer.cut()));
                textArea.ensureOneVisibleSelection();
                break;

            case PASTE:
                dstring clipboard = to!dstring(_sdl2.getClipboard());
                buffer.paste(clipboard);
                textArea.ensureOneVisibleSelection();
                break;

            case TAB:
                buffer.insertTab();
                textArea.ensureOneVisibleSelection();
        }
    }

    void saveCurrentBuffer()
    {
        if (_bufferEdit.isBoundToFileName())
        {
            string filepath = _bufferEdit.filePath();
            _bufferEdit.saveToFile(filepath);
            greenMessage(to!dstring(format("Saved to %s", filepath)));
        }
        else
        {
            redMessage("This buffer is unbounded, try :save <filename>");
        }
    }

    void greenMessage(dstring msg)
    {
        _cmdlinePanel.greenMessage(msg);
    }

    void redMessage(dstring msg)
    {
        _cmdlinePanel.redMessage(msg);
    }

    void executeCommandLine(dstring cmdline)
    {
        if (cmdline == ""d)
        {
            _bufferEdit.insertChar(':');
        }

        if (cmdline == "q"d || cmdline == "exit"d)
        {
            _finished = true;
            greenMessage("Bye"d);
        }
        else if (cmdline == "new"d || cmdline == "n"d)
        {
            _buffers ~= new Buffer;
            setCurrentBufferEdit(_buffers.length - 1);
            greenMessage("Created new file"d);
        }
        else if (cmdline == "save"d || cmdline == "s"d)
        {
            saveCurrentBuffer();
        }
        else if (cmdline == "load"d || cmdline == "l"d)
        {
            if (_bufferEdit.isBoundToFileName())
            {
                string filepath = _bufferEdit.filePath();
                _bufferEdit.loadFromFile(filepath);
                greenMessage(to!dstring(format("Loaded %s", filepath)));
            }
            else
                redMessage("This buffer is unbounded, try :load <filename>");
        }
        else if (cmdline == "undo" || cmdline == "u")
            _bufferEdit.undo();
        else if (cmdline == "redo" || cmdline == "r")
            _bufferEdit.redo();
        else if (cmdline == "clean")
        {
            _bufferEdit.cleanup();
            greenMessage("Buffer cleaned up"d);
        }
        else
            redMessage(to!dstring(format("Unknown command '%s'"d, cmdline)));
    }

}