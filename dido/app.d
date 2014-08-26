module dido.app;

import std.file;
import std.conv;

import gfm.sdl2;
import gfm.math;
import gfm.core;


import dido.buffer;
import dido.window;
import dido.command;
import dido.selection;
import dido.panel;
import dido.font;

final class App
{
public:
    this(string paths[])
    {
        foreach (ref path; paths)
        {
            SelectionBuffer buf = new SelectionBuffer;
            buf.loadFromFile(path);
            _buffers ~= buf;
        }

        // create an empty buffer if no file provided
        if (_buffers.length == 0)
        {
            SelectionBuffer buf = new SelectionBuffer;
            buf.initializeNew();
            _buffers ~= buf;
        }
        _bufferSelect = 0;

        _finished = false;
        _commandLineMode = false;

        _sdl2 = new SDL2(null);
        _sdlttf = new SDLTTF(_sdl2);
        _window = new Window(_sdl2, _sdlttf);

        _font = new Font(_sdlttf, _window.renderer(), "fonts/consola.ttf", 14);

        _sdl2.startTextInput();

        _mainPanel = new MainPanel;
        _menuPanel = new MenuPanel;
        _cmdlinePanel = new CommandLinePanel(_font);
        _solutionPanel = new SolutionPanel;
        _textArea = new TextArea;

        _mainPanel.children ~= [ _textArea, _solutionPanel, _menuPanel, _cmdlinePanel];
    }

    ~this()
    {
        close();
    }

    void close()
    {
        
        destroy(_textArea);
        destroy(_menuPanel);
        destroy(_cmdlinePanel);
        destroy(_solutionPanel);
        destroy(_mainPanel);

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
            renderer.setColor(23, 23, 23, 255);
            renderer.clear();

            int width = _window.getWidth();
            int height = _window.getHeight();
            int charWidth = _font.charWidth();
            int charHeight = _font.charHeight();

            bool drawCursors = (_timeSinceEvent % caretCycleTime) < caretBlinkTime;
            _cmdlinePanel.updateState(_commandLineMode);
            
            _textArea.setState(_font, _buffers[_bufferSelect], drawCursors);

            _mainPanel.reflow(box2i(0, 0, width, height), charWidth, charHeight);

            _mainPanel.render(renderer);
            
            renderer.present();
        }
    }


private:

    bool _finished;
    bool _commandLineMode;
    
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;
    SelectionBuffer[] _buffers;
    int _bufferSelect;
    uint _timeSinceEvent;

    MainPanel _mainPanel;
    MenuPanel _menuPanel;
    CommandLinePanel _cmdlinePanel;
    SolutionPanel _solutionPanel;
    TextArea _textArea;
    Font _font;

    void executeCommandLine(dstring cmdline)
    {
        vec3i green = vec3i(0, 255, 0);
        vec3i yellow = vec3i(255, 255, 0);
        vec3i red = vec3i(255, 0, 0);
        if (cmdline == "exit")
        {
            _finished = true;
            _cmdlinePanel.statusLine = "OK";
            _cmdlinePanel.statusColor = green;
        }
        else
        {
            _cmdlinePanel.statusLine = to!dstring(format("Unknown command '%s'"d, cmdline));
            _cmdlinePanel.statusColor = red;
        }
    }

    void execute(Command command)
    {
        SelectionBuffer buffer = _buffers[_bufferSelect];
        final switch (command.type) with (CommandType)
        {            
            case MOVE_UP:
                buffer.moveSelection(0, -1);                
                break;
            case MOVE_DOWN:
                buffer.moveSelection(0, 1);
                break;

            case MOVE_LEFT:
                buffer.moveSelection(-1, 0);
                break;

            case MOVE_RIGHT:            
                buffer.moveSelection(+1, 0);
                break;

            case MOVE_LINE_BEGIN:
                buffer.moveToLineBegin();
                break;

            case MOVE_LINE_END:
                buffer.moveToLineEnd();
                break;

            case TOGGLE_FULLSCREEN:
                _window.toggleFullscreen();
                break;

            case ROTATE_NEXT_BUFFER:
                _bufferSelect = (_bufferSelect + 1) % _buffers.length;
                _textArea.clearCamera();
                break;

            case ROTATE_PREVIOUS_BUFFER:
                _bufferSelect = (_bufferSelect + _buffers.length - 1) % _buffers.length;
                _textArea.clearCamera();
                break;

            case PAGE_UP:
                _textArea.moveCamera(0, -_textArea.position().height);
                break;

            case PAGE_DOWN:
                _textArea.moveCamera(0, _textArea.position().height);
                break;

            case ENTER_COMMANDLINE_MODE:
                if (!_commandLineMode)
                {
                    _cmdlinePanel.currentCommandLine = "";
                    _commandLineMode = true;
                }
                else
                {
                    // pressing : in command-line mode leaves it and insert ":"
                    // TODO insert :
                    _commandLineMode = false;                    
                }
                break;

            case BACKSPACE:
                if (_commandLineMode)
                {
                    if (_cmdlinePanel.currentCommandLine.length > 0)
                        _cmdlinePanel.currentCommandLine = _cmdlinePanel.currentCommandLine[0..$-1];
                }
                break;
            
            case RETURN:
                if (_commandLineMode)
                {
                    executeCommandLine(_cmdlinePanel.currentCommandLine);
                    goto case EXIT;
                }
                else
                {
                    // TODO
                    break;
                }

            case EXIT:
                if (_commandLineMode)
                    _commandLineMode = false;
                else
                    _finished = true;
                break;

            case INSERT_CHAR:
                if (_commandLineMode)
                    _cmdlinePanel.currentCommandLine ~= cast(dchar)(command.ch);
                else
                {
                    // TODO
                }
                break;
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
                        if (key.sym == SDLK_RETURN && ((key.mod & KMOD_ALT) != 0))
                            commands ~= Command(CommandType.TOGGLE_FULLSCREEN);                            
                        else if (key.sym == SDLK_ESCAPE)
                            commands ~= Command(CommandType.EXIT);
                        else if (key.sym == SDLK_RETURN)
                            commands ~= Command(CommandType.RETURN);
                        else if (key.sym == SDLK_LEFT)
                            commands ~= Command(CommandType.MOVE_LEFT);
                        else if (key.sym == SDLK_RIGHT)
                            commands ~= Command(CommandType.MOVE_RIGHT);
                        else if (key.sym == SDLK_UP)
                            commands ~= Command(CommandType.MOVE_UP);
                        else if (key.sym == SDLK_DOWN)
                            commands ~= Command(CommandType.MOVE_DOWN);
                        else if (key.sym == SDLK_BACKSPACE)
                            commands ~= Command(CommandType.BACKSPACE);
                        else if (key.sym == SDLK_END)
                            commands ~= Command(CommandType.MOVE_LINE_END);
                        else if (key.sym == SDLK_HOME)
                            commands ~= Command(CommandType.MOVE_LINE_BEGIN);
                        else if (key.sym == SDLK_PAGEUP && ((key.mod & KMOD_CTRL) != 0))
                            commands ~= Command(CommandType.ROTATE_PREVIOUS_BUFFER);
                        else if (key.sym == SDLK_PAGEDOWN && ((key.mod & KMOD_CTRL) != 0))
                            commands ~= Command(CommandType.ROTATE_NEXT_BUFFER);
                        else if (key.sym == SDLK_PAGEUP)
                            commands ~= Command(CommandType.PAGE_UP);
                        else if (key.sym == SDLK_PAGEDOWN)
                            commands ~= Command(CommandType.PAGE_DOWN);
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

                default:
                    break;
            }
        }

        foreach (cmd; commands)
        {
            _timeSinceEvent = 0;
            execute(cmd);
        }
    }    


}
