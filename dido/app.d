module dido.app;

import std.file;
import std.conv;

import gfm.sdl2;
import gfm.math;
import gfm.core;


import dido.buffer.buffer;
import dido.window;
import dido.command;
import dido.buffer.selection;
import dido.panel;
import dido.gui;
import dido.engine;
import dido.config;


final class App
{
public:
    this(DidoConfig config, string paths[])
    {
        _sdl2 = new SDL2(null);
        _sdlttf = new SDLTTF(_sdl2);
        _window = new Window(_sdl2, _sdlttf);

        _font = new Font(_sdlttf, _window.renderer(), config.fontFace, config.fontSize);

        _sdl2.startTextInput();

        _uiContext = new UIContext(_sdl2, _window.renderer(), _font);

        {
            import dido.panel.images;
            addAllImage(_uiContext);
        }

        _mainPanel = new MainPanel(_uiContext);
        _menuPanel = new MenuPanel(_uiContext);
        _cmdlinePanel = new CommandLinePanel(_uiContext);
        _solutionPanel = new SolutionPanel(_uiContext);
        _textArea = new TextArea(_uiContext, 16, true, true);

        _mainPanel.addChild(_textArea);
        _mainPanel.addChild(_solutionPanel);
        _mainPanel.addChild(_cmdlinePanel);
        _mainPanel.addChild(_menuPanel);
        _mainPanel.addChild(new UIImage(_uiContext, "corner"));

        _engine = new DidoEngine(_sdl2, _window, _textArea, _cmdlinePanel, paths);
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

        while(!_sdl2.wasQuitRequested() && !_engine.finished())
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

            _solutionPanel.updateState(_engine.buffers(), _engine.bufferSelect());
            _cmdlinePanel.updateState(_engine.isCommandLineMode(), drawCursors);
            
            _textArea.setState(_engine.currentEditBuffer(), !_engine.isCommandLineMode() && drawCursors);

            _mainPanel.reflow(box2i(0, 0, width, height));

            _mainPanel.render();
            
            renderer.present();
        }
    }


private:

    DidoEngine _engine;
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;
    
    uint _timeSinceEvent;

    MainPanel _mainPanel;
    MenuPanel _menuPanel;
    CommandLinePanel _cmdlinePanel;
    SolutionPanel _solutionPanel;
    TextArea _textArea;
    Font _font;
    UIContext _uiContext;
    

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
            _engine.executeCommand(cmd);
        }
    }        
}
