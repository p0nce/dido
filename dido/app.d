module dido.app;

import std.file;
import std.conv;
import std.string;

import gfm.sdl2;
import gfm.math;

import dido.buffer.buffer;
import dido.window;
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


        _textArea = new TextArea(_uiContext, 16, true, true);

        _cmdlinePanel = new CommandLinePanel(_uiContext);
        _solutionPanel = new SolutionPanel(_uiContext);

        _engine = new DidoEngine(_sdl2, _window, _textArea, _cmdlinePanel, paths);
        _mainPanel = new MainPanel(_uiContext);
        _menuPanel = new MenuPanel(_uiContext, _engine);


        _mainPanel.addChild(_textArea);
        _mainPanel.addChild(_solutionPanel);
        _mainPanel.addChild(_cmdlinePanel);
        _mainPanel.addChild(_menuPanel);
        _mainPanel.addChild(new UIImage(_uiContext, "corner"));

        _needReflow = true;
        _needRedraw = true;
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

        _timeSinceKeypress = 0;

        bool lastdrawCursors = false;

        bool firstFrame = true;

        while(!_sdl2.wasQuitRequested() && !_engine.finished())
        {
            uint time = SDL_GetTicks();
            uint deltaTime = time - lastTime;
            lastTime = time;
            _timeSinceKeypress += deltaTime;

            if(!firstFrame)
                waitForAnEventThenProcessThemAll();

            firstFrame = false;

            SDL2Renderer renderer = _window.renderer();

            int width = _window.getWidth();
            int height = _window.getHeight();
            int charWidth = _font.charWidth();
            int charHeight = _font.charHeight();

            bool drawCursors = (_timeSinceKeypress % caretCycleTime) < caretBlinkTime;

            if (lastdrawCursors != drawCursors)
                _needRedraw = true;

            lastdrawCursors = drawCursors;

            // reflow
            if (_needReflow)
            {
                _solutionPanel.updateState(_engine.buffers(), _engine.bufferSelect());
                _mainPanel.reflow(box2i(0, 0, width, height));

                _needReflow = false;
            }

            // redraw
            if (_needRedraw)
            {
                _cmdlinePanel.updateMode(_engine.isCommandLineMode());
                _cmdlinePanel.updateCursorState(drawCursors);
                _textArea.setState(_engine.currentEditBuffer(), !_engine.isCommandLineMode() && drawCursors);

                renderer.setViewportFull();

                _mainPanel.render();
                renderer.present();
            }
        }
    }


private:

    DidoEngine _engine;
    SDL2 _sdl2;
    SDLTTF _sdlttf;
    Window _window;

    uint _timeSinceKeypress;

    MainPanel _mainPanel;
    MenuPanel _menuPanel;
    CommandLinePanel _cmdlinePanel;
    SolutionPanel _solutionPanel;
    TextArea _textArea;
    Font _font;
    UIContext _uiContext;

    bool _needReflow;
    bool _needRedraw;

    void dealWithEvent(ref SDL_Event event)
    {
        switch (event.type)
        {
            case SDL_KEYDOWN:
                {
                    _timeSinceKeypress = 0;
                    auto key = event.key.keysym;
                    bool alt = (key.mod & KMOD_ALT) != 0;
                    bool shift = (key.mod & KMOD_SHIFT) != 0;
                    bool ctrl = (key.mod & KMOD_CTRL) != 0;
                    string sshift = shift ? "#t" : "#f";

                    if (key.sym == SDLK_RETURN && alt)
                        _engine.executeScheme("(toggle-fullscreen)");
                    else if (key.sym == SDLK_UP && ctrl && alt)
                        _engine.executeScheme("(extend-selection-vertical -1)");
                    else if (key.sym == SDLK_DOWN && ctrl && alt)
                        _engine.executeScheme("(extend-selection-vertical 1)");
                    else if (key.sym == SDLK_LEFT && ctrl)
                        _engine.executeScheme(format("(move-word-left %s)", sshift));
                    else if (key.sym == SDLK_RIGHT && ctrl)
                        _engine.executeScheme(format("(move-word-right %s)", sshift));
                    else if (key.sym == SDLK_ESCAPE)
                        _engine.executeScheme("(escape)");
                    else if (key.sym == SDLK_RETURN)
                        _engine.enter();

                    // copy/cut/paste
                    else if (key.sym == SDLK_c && ctrl)
                        _engine.executeScheme("(copy)");
                    else if (key.sym == SDLK_x && ctrl)
                        _engine.executeScheme("(cut)");
                    else if (key.sym == SDLK_v && ctrl)
                        _engine.executeScheme("(paste)");
                    else if (key.sym == SDLK_COPY)
                        _engine.executeScheme("(copy)");
                    else if (key.sym == SDLK_CUT)
                        _engine.executeScheme("(cut)");
                    else if (key.sym == SDLK_PASTE)
                        _engine.executeScheme("(paste)");
                    else if (key.sym == SDLK_DELETE && shift)
                        _engine.executeScheme("(cut)");
                    else if (key.sym == SDLK_INSERT && ctrl)
                        _engine.executeScheme("(copy)");
                    else if (key.sym == SDLK_INSERT && shift)
                        _engine.executeScheme("(paste)");
                    else if (key.sym == SDLK_LEFT)
                        _engine.executeScheme(format("(move-horizontal -1 %s)", sshift));
                    else if (key.sym == SDLK_RIGHT)
                        _engine.executeScheme(format("(move-horizontal 1 %s)", sshift));
                    else if (key.sym == SDLK_UP)
                        _engine.executeScheme(format("(move-vertical -1 %s)", sshift));
                    else if (key.sym == SDLK_DOWN)
                        _engine.executeScheme(format("(move-vertical 1 %s)", sshift));
                    else if (key.sym == SDLK_BACKSPACE)
                        _engine.executeScheme("(delete-selection #t)");
                    else if (key.sym == SDLK_DELETE)
                        _engine.executeScheme("(delete-selection #f)");
                    else if (key.sym == SDLK_HOME && ctrl)
                        _engine.executeScheme(format("(move-buffer-start %s)", sshift));
                    else if (key.sym == SDLK_END && ctrl)
                        _engine.executeScheme(format("(move-buffer-end %s)", sshift));
                    else if (key.sym == SDLK_a && ctrl)
                        _engine.executeScheme("(select-all)");
                    else if (key.sym == SDLK_END)
                        _engine.executeScheme(format("(move-line-end %s)", sshift));
                    else if (key.sym == SDLK_HOME)
                        _engine.executeScheme(format("(move-line-start %s)", sshift));
                    else if (key.sym == SDLK_PAGEUP && ctrl)
                        _engine.executeScheme("(previous-buffer)");
                    else if (key.sym == SDLK_PAGEDOWN && ctrl)
                        _engine.executeScheme("(next-buffer)");
                    else if (key.sym == SDLK_PAGEUP)
                        _engine.executeScheme(format("(move-vertical (- (visible-lines)) %s)", sshift));
                    else if (key.sym == SDLK_PAGEDOWN)
                        _engine.executeScheme(format("(move-vertical (visible-lines) %s)", sshift));
                    else if (key.sym == SDLK_z && ctrl)
                        _engine.executeScheme("(undo)");
                    else if (key.sym == SDLK_y && ctrl)
                        _engine.executeScheme("(redo)");
                    else if (key.sym == SDLK_s && ctrl)
                        _engine.executeScheme("(save)");
                    else if (key.sym == SDLK_F4)
                        _engine.executeScheme("(build)");
                    else if (key.sym == SDLK_F5)
                        _engine.executeScheme("(run)");
                    else if (key.sym == SDLK_TAB)
                        _engine.executeScheme("(indent)");
                    else
                    {
                    }

                    _needReflow = true;
                    _needRedraw = true;
                    break;
                }

            case SDL_TEXTINPUT:
                {
                    _timeSinceKeypress = 0;
                    const(char)[] s = fromStringz(event.text.text.ptr);

                    if (s == ":")
                        _engine.enterCommandLineMode();
                    else
                    {
                        dstring ds = to!dstring(s);
                        foreach(ch; ds)
                            _engine.executeScheme(format("(insert-char %s)", to!int(ch)));
                    }
                }
                _needRedraw = true;
                break;


            case SDL_MOUSEBUTTONDOWN:
                {
                    const (SDL_MouseButtonEvent*) mbEvent = &event.button;

                    // undo
                    if (mbEvent.button == SDL_BUTTON_X1)
                        _engine.executeScheme("(undo)");
                    else if (mbEvent.button == SDL_BUTTON_X2)
                        _engine.executeScheme("(redo)");
                    else
                        _mainPanel.mouseClick(_sdl2.mouse.x, _sdl2.mouse.y, mbEvent.button, mbEvent.clicks > 1);
                    _needRedraw = true;
                    break;
                }

            case SDL_MOUSEBUTTONUP:
                {
                    const (SDL_MouseButtonEvent*) mbEvent = &event.button;
                    _mainPanel.mouseRelease(_sdl2.mouse.x, _sdl2.mouse.y, mbEvent.button);
                    _needRedraw = true;
                    break;
                }

            case SDL_MOUSEWHEEL:
                {
                    _mainPanel.mouseWheel(_sdl2.mouse.x, _sdl2.mouse.y, _sdl2.mouse.wheelDeltaX(), _sdl2.mouse.wheelDeltaY());
                    _needRedraw = true;
                    break;
                }

            case SDL_MOUSEMOTION:
                _mainPanel.mouseMove(_sdl2.mouse.x, _sdl2.mouse.y, _sdl2.mouse.lastDeltaX(), _sdl2.mouse.lastDeltaY());
                _needRedraw = true;
                break;

            case SDL_WINDOWEVENT:
                /*{
                    const (SDL_WindowEvent*) windowEvent = &event.window;

                if (windowEvent.event == ) {*/
                

                _needReflow = true;
                _needRedraw = true;
                break;


            default:
                break;
        }
    }

    void waitForAnEventThenProcessThemAll()
    {
        SDL_Event event;
        if (_sdl2.waitEventTimeout(&event, 50))
        {
            dealWithEvent(event);
            while (_sdl2.pollEvent(&event))
            {
                dealWithEvent(event);
            }
        }
    }
}
