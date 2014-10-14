module dido.engine;

import std.process;
import std.string;

import gfm.sdl2;

import dido.panel;
import dido.command;
import dido.buffer.buffer;
import dido.window;

import schemed;

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

    // scheme-d environment
    Environment _env;

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

        _env = defaultEnvironment();
        addBuiltins(_env);
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

            case SELECT_ALL_BUFFER:
                buffer.selectAll();
                textArea.ensureOneVisibleSelection();
                break;

            case TAB:
                buffer.insertTab();
                textArea.ensureOneVisibleSelection();
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

    void executeScheme(string code)
    {
        try
        {            
            Atom result = execute(code, _env); // result is discarded
        }
        catch(SchemeParseException e)
        {
            // try to execute again, but with parens appended

            try
            {
                Atom result = execute("(" ~ code ~ ")", _env);
            }
            catch(SchemeParseException e2)
            {
                // another error, print the _first_ message
                redMessage(to!dstring(e.msg));
            }
            catch(SchemeEvalException e2)
            {
                redMessage(to!dstring(e2.msg));
            }
        }
        catch(SchemeEvalException e)
        {
            redMessage(to!dstring(e.msg));
        }
    }

    void executeCommandLine(dstring cmdline)
    {
        if (cmdline == ""d)
            _bufferEdit.insertChar(':');
        else
            executeScheme(to!string(cmdline));
    }

    bool checkArgs(string func, Atom[] args, int min, int max)
    {
        if (args.length < min)
        {
            redMessage(to!dstring(format("%s expects %s to %s arguments", to!string(func), min, max)));
            return false;
        }
        else if (args.length > max)
        {
            redMessage(to!dstring(format("%s expects %s to %s arguments", to!string(func), min, max)));
            return false;
        }
        else
            return true;
    }

    void addBuiltins(Environment env)
    {
        env.addBuiltin("exit", (Atom[] args)
        {
            if (!checkArgs("q|exit", args, 0, 0))
                return makeNil();
            _finished = true;
            greenMessage("Bye"d);
            return makeNil(); 
        });

        env.addBuiltin("undo", (Atom[] args)
        {
            if (!checkArgs("u|undo", args, 0, 0))
                return makeNil();
            currentBuffer().undo();
            currentTextArea().ensureOneVisibleSelection();
            return makeNil(); 
        });

        env.addBuiltin("redo", (Atom[] args)
        {
            if (!checkArgs("r|redo", args, 0, 0))
                return makeNil();
            currentBuffer().redo();
            currentTextArea().ensureOneVisibleSelection();
            return makeNil(); 
        });

        env.addBuiltin("new", (Atom[] args)
        {
            if (!checkArgs("n|new", args, 0, 0))
                return makeNil();
            _buffers ~= new Buffer;
            setCurrentBufferEdit(_buffers.length - 1);
            greenMessage("Created new file"d);
            return makeNil(); 
        });

        env.addBuiltin("clean", (Atom[] args)
        {
            if (!checkArgs("clean", args, 0, 0))
                return makeNil();
            _bufferEdit.cleanup();
            greenMessage("Buffer cleaned up"d);
            return makeNil();
        });

        env.addBuiltin("save", (Atom[] args)
        {
            if (!checkArgs("s|save", args, 0, 0))
                return makeNil();

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
            return makeNil();
        });

        env.addBuiltin("load", (Atom[] args)
        {
            if (!checkArgs("l|load", args, 0, 0))
                return makeNil();

            if (_bufferEdit.isBoundToFileName())
            {
                string filepath = _bufferEdit.filePath();
                _bufferEdit.loadFromFile(filepath);
                greenMessage(to!dstring(format("Loaded %s", filepath)));
            }
            else
                redMessage("This buffer is unbounded, try :load <filename>");
            return makeNil();
        });

        env.addBuiltin("build", (Atom[] args)
        {
            if (!checkArgs("build", args, 0, 0))
                return makeNil();
            auto dubResult = std.process.execute(["dub", "build"]);
            if (dubResult.status != 0)
                redMessage(to!dstring(format("DUB returned %s", dubResult.status)));
            return makeNil();
        });

        env.addBuiltin("run", (Atom[] args)
        {
            if (!checkArgs("run", args, 0, 0))
                return makeNil();
            auto dubResult = std.process.execute(["dub", "run"]);
            if (dubResult.status != 0)
                redMessage(to!dstring(format("DUB returned %s", dubResult.status)));
            return makeNil();
        });

        env.addBuiltin("copy", (Atom[] args)
        {
            if (!checkArgs("copy", args, 0, 0))
                return makeNil();
            _sdl2.setClipboard(to!string(currentBuffer.copy()));
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("cut", (Atom[] args)
        {
            if (!checkArgs("cut", args, 0, 0))
                return makeNil();
            _sdl2.setClipboard(to!string(currentBuffer.cut()));
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("paste", (Atom[] args)
        {
            if (!checkArgs("paste", args, 0, 0))
                return makeNil();
            dstring clipboard = to!dstring(_sdl2.getClipboard());
            currentBuffer.paste(clipboard);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });


        // aliases
        env.values["n"] = env.values["new"];
        env.values["s"] = env.values["save"];
        env.values["l"] = env.values["load"];
        env.values["u"] = env.values["undo"];
        env.values["r"] = env.values["redo"];
        env.values["q"] = env.values["exit"];

        env.addBuiltin("visible-lines", (Atom[] args)
        {
            if (!checkArgs("visible-lines", args, 0, 0))
                return makeNil();
            double lines = _textArea.numVisibleLines;
            return Atom(lines);
        });

        env.addBuiltin("move-vertical", (Atom[] args)
        {
            if (!checkArgs("move-vertical", args, 2, 2))
                return makeNil();           
            int displacement = to!int(toDouble(args[0]));
            bool shift = toBool(args[1]);
            currentBuffer.moveSelectionVertical(displacement, shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-horizontal", (Atom[] args)
        {
            if (!checkArgs("move-horizontal", args, 2, 2))
                return makeNil();           
            int displacement = to!int(toDouble(args[0]));
            bool shift = toBool(args[1]);
            currentBuffer.moveSelectionHorizontal(displacement, shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-buffer-start", (Atom[] args)
        {
            if (!checkArgs("move-buffer-start", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveSelectionToBufferStart(shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });  

        env.addBuiltin("move-buffer-end", (Atom[] args)
        {
            if (!checkArgs("move-buffer-end", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveSelectionToBufferStart(shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-word-left", (Atom[] args)
        {
            if (!checkArgs("move-word-left", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveSelectionWord(-1, shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-word-right", (Atom[] args)
        {
            if (!checkArgs("move-word-right", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveSelectionWord(1, shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-line-start", (Atom[] args)
        {
            if (!checkArgs("move-line-start", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveToLineBegin(shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        });

        env.addBuiltin("move-line-end", (Atom[] args)
        {
            if (!checkArgs("move-line-end", args, 1, 1))
                return makeNil();           
            bool shift = toBool(args[0]);
            currentBuffer.moveToLineEnd(shift);
            currentTextArea.ensureOneVisibleSelection();
            return makeNil();
        }); 
    }
}