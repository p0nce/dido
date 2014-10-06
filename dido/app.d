module dido.app;

import std.file;
import std.conv;
import std.process : execute;

import gfm.sdl2;
import gfm.math;
import gfm.core;


import dido.buffer.buffer;
import dido.window;
import dido.command;
import dido.buffer.selection;
import dido.panel;
import dido.gui;
import dido.config;


final class App
{
public:
    this(DidoConfig config, string paths[])
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

        _finished = false;
        _commandLineMode = false;

        _sdl2 = new SDL2(null);
        _sdlttf = new SDLTTF(_sdl2);
        _window = new Window(_sdl2, _sdlttf);

        _font = new Font(_sdlttf, _window.renderer(), config.fontFace, config.fontSize);

        _sdl2.startTextInput();

        _uiContext = new UIContext(_sdl2, _window.renderer(), _font);

        _mainPanel = new MainPanel(_uiContext);
        _menuPanel = new MenuPanel(_uiContext);
        _cmdlinePanel = new CommandLinePanel(_uiContext);
        _solutionPanel = new SolutionPanel(_uiContext);
        _textArea = new TextArea(_uiContext, 16, true, true);

        _mainPanel.addChild(_textArea);
        _mainPanel.addChild(_solutionPanel);
        _mainPanel.addChild(_cmdlinePanel);
        _mainPanel.addChild(_menuPanel);
    }

    ~this()
    {
        close();
    }

    void close()
    {
        _mainPanel.close();
        _uiContext.close();
        _sdl2.stopTextInput();
        _font.close();
        _window.close();
        _sdlttf.close();
        _sdl2.close();
    }

    void mainLoop()
    {
        uint caretBlinkTime = 530 ; // default value on Win7
        uint caretCycleTime = caretBlinkTime * 2; // default value on Win7

        uint lastTime = SDL_GetTicks();

        _timeSinceEvent = 0;

        while(!_sdl2.wasQuitRequested() && !_finished)
        {     
            uint time = SDL_GetTicks();
            uint deltaTime = time - lastTime;
            lastTime = time;
            _timeSinceEvent += deltaTime;

            pollCommandsFromKeyboard();

            SDL2Renderer renderer = _window.renderer();
            
            renderer.setViewportFull();
            renderer.setColor(20, 19, 18, 255);
            renderer.clear();

            int width = _window.getWidth();
            int height = _window.getHeight();
            int charWidth = _font.charWidth();
            int charHeight = _font.charHeight();

            bool drawCursors = (_timeSinceEvent % caretCycleTime) < caretBlinkTime;

            _solutionPanel.updateState(_buffers, _bufferSelect);
            _cmdlinePanel.updateState(_commandLineMode, drawCursors);
            
            _textArea.setState(_buffers[_bufferSelect], drawCursors);

            _mainPanel.reflow(box2i(0, 0, width, height));

            _mainPanel.render();
            
            renderer.present();
        }
    }


private:

    bool _finished;
    bool _commandLineMode;
    
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;
    Buffer[] _buffers;
    Buffer _bufferEdit; // current buffer in edit area
    int _bufferSelect;
    uint _timeSinceEvent;

    MainPanel _mainPanel;
    MenuPanel _menuPanel;
    CommandLinePanel _cmdlinePanel;
    SolutionPanel _solutionPanel;
    TextArea _textArea;
    Font _font;
    UIContext _uiContext;

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

    void setCurrentBufferEdit(int bufferSelect)
    {
        _bufferSelect = bufferSelect;
        _bufferEdit = _buffers[_bufferSelect];
        _bufferEdit.ensureLoaded();
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

            case SCROLL_ONE_LINE_UP:
                textArea.moveCamera(0, -_font.charHeight);
                break;

            case SCROLL_ONE_LINE_DOWN:
                textArea.moveCamera(0, +_font.charHeight);
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


    // retrieve list of commands to execute given by keyboard input
    void pollCommandsFromKeyboard()
    {
        Command[] commands;
        SDL_Event event;
        while (_sdl2.pollEvent(&event))
        {
            switch (event.type)
            {
                case SDL_KEYDOWN:
                    {
                        auto key = event.key.keysym;
                        bool alt = (key.mod & KMOD_ALT) != 0;
                        bool shift = (key.mod & KMOD_SHIFT) != 0;
                        bool ctrl = (key.mod & KMOD_CTRL) != 0;

                        if (key.sym == SDLK_RETURN && alt)
                            commands ~= Command(CommandType.TOGGLE_FULLSCREEN);     
                        else if (key.sym == SDLK_UP && ctrl && alt)
                            commands ~= Command(CommandType.EXTEND_SELECTION_UP);
                        else if (key.sym == SDLK_DOWN && ctrl && alt)
                            commands ~= Command(CommandType.EXTEND_SELECTION_DOWN);
                        else if (key.sym == SDLK_UP && ctrl)
                            commands ~= Command(CommandType.SCROLL_ONE_LINE_UP);
                        else if (key.sym == SDLK_DOWN && ctrl)
                            commands ~= Command(CommandType.SCROLL_ONE_LINE_DOWN);
                        else if (key.sym == SDLK_LEFT && ctrl)
                            commands ~= Command(CommandType.MOVE_WORD_LEFT, shift);
                        else if (key.sym == SDLK_RIGHT && ctrl)
                            commands ~= Command(CommandType.MOVE_WORD_RIGHT, shift);
                        else if (key.sym == SDLK_ESCAPE)
                            commands ~= Command(CommandType.ESCAPE);
                        else if (key.sym == SDLK_RETURN)
                            commands ~= Command(CommandType.RETURN);

                        // copy/cut/paste
                        else if (key.sym == SDLK_c && ctrl)
                            commands ~= Command(CommandType.COPY);
                        else if (key.sym == SDLK_x && ctrl)
                            commands ~= Command(CommandType.CUT);
                        else if (key.sym == SDLK_v && ctrl)
                            commands ~= Command(CommandType.PASTE);
                        else if (key.sym == SDLK_COPY)
                            commands ~= Command(CommandType.COPY);
                        else if (key.sym == SDLK_CUT)
                            commands ~= Command(CommandType.CUT);
                        else if (key.sym == SDLK_PASTE)
                            commands ~= Command(CommandType.PASTE);
                        else if (key.sym == SDLK_DELETE && shift)
                            commands ~= Command(CommandType.CUT);
                        else if (key.sym == SDLK_INSERT && ctrl)
                            commands ~= Command(CommandType.COPY);
                        else if (key.sym == SDLK_INSERT && shift)
                            commands ~= Command(CommandType.PASTE);


                        else if (key.sym == SDLK_LEFT)
                            commands ~= Command(CommandType.MOVE_LEFT, shift);
                        else if (key.sym == SDLK_RIGHT)
                            commands ~= Command(CommandType.MOVE_RIGHT, shift);
                        else if (key.sym == SDLK_UP)
                            commands ~= Command(CommandType.MOVE_UP, shift);
                        else if (key.sym == SDLK_DOWN)
                            commands ~= Command(CommandType.MOVE_DOWN, shift);
                        else if (key.sym == SDLK_BACKSPACE)
                            commands ~= Command(CommandType.BACKSPACE);
                        else if (key.sym == SDLK_DELETE)
                            commands ~= Command(CommandType.DELETE);
                        else if (key.sym == SDLK_HOME && ctrl)
                            commands ~= Command(CommandType.GOTO_START_OF_BUFFER, shift);
                        else if (key.sym == SDLK_END && ctrl)
                            commands ~= Command(CommandType.GOTO_END_OF_BUFFER, shift);
                        else if (key.sym == SDLK_a && ctrl)
                            commands ~= Command(CommandType.SELECT_ALL_BUFFER);
                        else if (key.sym == SDLK_END)
                            commands ~= Command(CommandType.MOVE_LINE_END, shift);
                        else if (key.sym == SDLK_HOME)
                            commands ~= Command(CommandType.MOVE_LINE_BEGIN, shift);
                        else if (key.sym == SDLK_PAGEUP && ctrl)
                            commands ~= Command(CommandType.ROTATE_PREVIOUS_BUFFER);
                        else if (key.sym == SDLK_PAGEDOWN && ctrl)
                            commands ~= Command(CommandType.ROTATE_NEXT_BUFFER);
                        else if (key.sym == SDLK_PAGEUP)
                            commands ~= Command(CommandType.PAGE_UP, shift);
                        else if (key.sym == SDLK_PAGEDOWN)
                            commands ~= Command(CommandType.PAGE_DOWN, shift);
                        else if (key.sym == SDLK_z && ctrl)
                            commands ~= Command(CommandType.UNDO);
                        else if (key.sym == SDLK_y && ctrl)
                            commands ~= Command(CommandType.REDO);
                        else if (key.sym == SDLK_s && ctrl)
                            commands ~= Command(CommandType.SAVE);
                        else if (key.sym == SDLK_F4)
                            commands ~= Command(CommandType.BUILD);
                        else if (key.sym == SDLK_F5)
                            commands ~= Command(CommandType.RUN);
                        else if (key.sym == SDLK_TAB)
                            commands ~= Command(CommandType.TAB);
                        else 
                        {
                        }
                        break;
                    }

                case SDL_TEXTINPUT:
                    {
                        string s = sanitizeUTF8(event.text.text.ptr);

                        if (s == ":")
                        {
                            commands ~= Command(CommandType.ENTER_COMMANDLINE_MODE);
                        }
                        else
                        {
                            dstring ds = to!dstring(s);

                            foreach(ch; ds)
                                commands ~= Command(CommandType.INSERT_CHAR, ch);
                        }
                    }
                    break;


                case SDL_MOUSEBUTTONDOWN:
                {
                    const (SDL_MouseButtonEvent*) mbEvent = &event.button;

                    // undo
                    if (mbEvent.button == SDL_BUTTON_X1)
                        commands ~= Command(CommandType.UNDO);
                    else if (mbEvent.button == SDL_BUTTON_X2)
                        commands ~= Command(CommandType.REDO);
                    else
                        _mainPanel.mouseClick(_sdl2.mouse.x, _sdl2.mouse.y, mbEvent.button, mbEvent.clicks > 1);
                    break;
                }

                case SDL_MOUSEBUTTONUP:
                {
                    const (SDL_MouseButtonEvent*) mbEvent = &event.button;
                    _mainPanel.mouseRelease(_sdl2.mouse.x, _sdl2.mouse.y, mbEvent.button);
                    break;
                }

                case SDL_MOUSEWHEEL:
                {
                    _mainPanel.mouseWheel(_sdl2.mouse.x, _sdl2.mouse.y, _sdl2.mouse.wheelDeltaX(), _sdl2.mouse.wheelDeltaY());
                    break;
                }

                case SDL_MOUSEMOTION:
                    _mainPanel.mouseMove(_sdl2.mouse.x, _sdl2.mouse.y, _sdl2.mouse.lastDeltaX(), _sdl2.mouse.lastDeltaY());
                    break;

                default:
                    break;
            }
        }



        foreach (cmd; commands)
        {
            _timeSinceEvent = 0;
            executeCommand(cmd);
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
}
