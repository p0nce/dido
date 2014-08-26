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

final class App
{
public:
    this(string path)
    {
        _buffer = new SelectionBuffer();
        _buffer.loadFromFile(path);


        _finished = false;
        _commandLineMode = false;
        _currentCommandLine = "";
        _statusLine = "";

        _sdl2 = new SDL2(null);
        _sdlttf = new SDLTTF(_sdl2);
        _window = new Window(_sdl2, _sdlttf);

        _sdl2.startTextInput();
    }

    ~this()
    {
        close();
    }

    void close()
    {
        _sdl2.stopTextInput();
//        _buffer.close();
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
            int charWidth = _window.charWidth();
            int charHeight = _window.charHeight();

            int widthOfSolutionExplorer = 250;
            int widthOfLineNumberMargin = charWidth * 6;
            int widthOfLeftScrollbar = 12;
            int marginScrollbar = 4;
            int marginCmdline = 4;

            int heightOfTopBar = 8 + charHeight;
            int heightOfCommandLineBar = 8 + charHeight;

            renderer.setColor(34, 34, 34, 255);
            renderer.fillRect(0, heightOfTopBar, widthOfSolutionExplorer, height - heightOfCommandLineBar - heightOfTopBar);

            renderer.setColor(28, 28, 28, 255);
            renderer.fillRect(widthOfSolutionExplorer, heightOfTopBar, widthOfLineNumberMargin, height - heightOfCommandLineBar - heightOfTopBar);

            renderer.setColor(34, 34, 34, 128);
            renderer.fillRect(width - marginScrollbar - widthOfLeftScrollbar, heightOfTopBar + marginScrollbar, widthOfLeftScrollbar, height - marginScrollbar * 2 - heightOfCommandLineBar - heightOfTopBar);

            int marginEditor = 16;

            int editPosX = -_cameraX + widthOfSolutionExplorer + widthOfLineNumberMargin + marginEditor;
            int editPosY = -_cameraY + marginEditor + heightOfTopBar;
            
            for (int i = 0; i < _buffer.numLines(); ++i)
            {
                dstring line = _buffer.line(i);
                dstring lineNumber = to!dstring(i + 1) ~ " ";
                while (lineNumber.length < 6)
                {
                    lineNumber = " "d ~ lineNumber;
                }
                
                _window.setColor(49, 97, 107, 160);
                _window.renderString(lineNumber, widthOfSolutionExplorer, -_cameraY + marginEditor + i * charHeight + heightOfTopBar);


                int posX = editPosX;
                int posY = editPosY + i * charHeight;
                
                foreach(dchar ch; line)
                {
                    switch (ch)
                    {
                        case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                            _window.setColor(255, 200, 200);
                            break;

                        case '+', '-', '=', '>', '<', '^', ',', '$', '|', '&', '`', '/', '@', '.', '"', '[', ']', '?', ':', '\'', '\\':
                            _window.setColor(255, 255, 106);
                            break;

                        case '(', ')', ';':
                            _window.setColor(255, 255, 150);
                            break;

                        case '{':
                            _window.setColor(108, 108, 128);
                            break;

                        case '}':
                            _window.setColor(108, 108, 138);
                            break;

                        default:
                            _window.setColor(250, 250, 250);
                            break;
                    }
                    
                    _window.renderChar(ch, posX, posY);
                    posX += charWidth;
                }
            }

            // draw cursors
            SelectionSet selset = _buffer.selectionSet;
            foreach(Selection sel; selset.selections)
            {
                bool drawCursors = (_timeSinceEvent % caretCycleTime) < caretBlinkTime;
                renderSelection(renderer, editPosX, editPosY, sel, drawCursors);
            }

            renderer.setColor(14, 14, 14, 230);
            renderer.fillRect(0, 0,  width, heightOfTopBar);

            renderer.setColor(14, 14, 14, 230);            
            renderer.fillRect(0, height - heightOfCommandLineBar,  width, heightOfCommandLineBar);

            {
                // commandline bar at bottom

                int textPosx = 4 + charWidth;
                int textPosy = height - heightOfCommandLineBar + 4;

                if (_commandLineMode)
                {
                    _window.setColor(255, 255, 0, 255);
                    _window.renderString(":", 4, height - heightOfCommandLineBar + 4);
                    _window.setColor(255, 255, 128, 255);
                    _window.renderString(_currentCommandLine, textPosx, textPosy);
                }
                else
                {
                    // Write status line
                    _window.setColor(_statusColor.r, _statusColor.g, _statusColor.b, 255);
                    _window.renderString(_statusLine, textPosx, textPosy);
                }
            }

            renderer.present();
        }
    }


private:

    int _cameraX = 0;
    int _cameraY = 0;

    bool _finished;
    bool _commandLineMode;
    dstring _currentCommandLine;
    dstring _statusLine;
    vec3i _statusColor;
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;
    SelectionBuffer _buffer;
    uint _timeSinceEvent;

    void executeCommandLine(dstring cmdline)
    {
        vec3i green = vec3i(0, 255, 0);
        vec3i yellow = vec3i(255, 255, 0);
        vec3i red = vec3i(255, 0, 0);
        if (cmdline == "exit")
        {
            _finished = true;
            _statusLine = "OK";
            _statusColor = green;
        }
        else
        {
            _statusLine = to!dstring(format("Unknown command '%s'"d, cmdline));
            _statusColor = red;
        }
    }

    void execute(Command command)
    {
        final switch (command.type) with (CommandType)
        {            
            case MOVE_UP:
                _buffer.moveSelection(0, -1);                
                break;
            case MOVE_DOWN:
                _buffer.moveSelection(0, 1);
                break;

            case MOVE_LEFT:
                _buffer.moveSelection(-1, 0);
                break;

            case MOVE_RIGHT:            
                _buffer.moveSelection(+1, 0);
                break;

            case MOVE_LINE_END:
            case MOVE_LINE_BEGIN:
                break;

            case TOGGLE_FULLSCREEN:
                _window.toggleFullscreen();
                break;


            case ENTER_COMMANDLINE_MODE:
                if (!_commandLineMode)
                {
                    _currentCommandLine = "";
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
                    if (_currentCommandLine.length > 0)
                        _currentCommandLine = _currentCommandLine[0..$-1];

                }
                break;
            
            case RETURN:
                if (_commandLineMode)
                {
                    executeCommandLine(_currentCommandLine);
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
                    _currentCommandLine ~= cast(dchar)(command.ch);
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

    void renderSelection(SDL2Renderer renderer, int offsetX, int offsetY, Selection selection, bool drawCursors)
    {
        // draw the cursor part
        if (drawCursors)
        {
            int startX = offsetX + selection.start.column * _window.charWidth();
            int startY = offsetY + selection.start.line * _window.charHeight();

            renderer.setColor(255, 255, 255, 255);
            renderer.fillRect(startX, startY, 1, _window.charHeight() - 1);
        }

        if (selection.hasSelectedArea)
        {
            int stopX = offsetX + selection.stop.column * _window.charWidth();
            int stopY = offsetY + selection.stop.line * _window.charHeight();

            // draw the cursor part
            renderer.setColor(128, 128, 128, 255);
            renderer.fillRect(stopX, stopY, 1, _window.charHeight() - 1);
        }

        // TODO draw extent
    }
}
