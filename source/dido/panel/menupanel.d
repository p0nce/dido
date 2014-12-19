module dido.panel.menupanel;

import std.conv;

import dido.gui;
import dido.app;
import dido.engine;

class MenuPanel : UIElement
{
    this(UIContext context, DidoEngine engine)
    {
        super(context);

        addChild(new BuildButton(context, engine));
        addChild(new RunButton(context, engine));

        addChild(new CompilerCombo(context, engine));
        addChild(new ArchCombo(context, engine));
        addChild(new BuildCombo(context, engine));
        addChild(new DlangOrgButton(context));
        addChild(new DubRegistryButton(context));
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.max.y = availableSpace.min.y + 8 + 8 + charHeight;

        int margin = 4;

        availableSpace = _position.shrink(margin);

        availableSpace.min.x += 16 + 6 + margin;

        void reflowChild(int n)
        {
            child(n).reflow(availableSpace);
            availableSpace.min.x = child(n).position.max.x + margin;
        }

        reflowChild(0);
        reflowChild(1);
        reflowChild(2);
        reflowChild(3);
        reflowChild(4);
        reflowChild(5);
        reflowChild(6);
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(15, 14, 14, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        renderer.copy(context.image("dido"), 6, (_position.height - 20) / 2);
    }
}

class BuildCombo : ComboBox
{
    this(UIContext context, DidoEngine engine)
    {
        _engine = engine;
        super(context, 
              [ "debug", "plain", "release", "nobounds", "unittest", "profile", "docs", "ddox", "cov", "test-cov" ], 
              [ "debug", "plain", "release", "release-nobounds", "unittest", "profile", "docs", "ddox", "cov", "unittest-cov" ], "cycle");        
    }

    override void onChoice(int n)
    {
        _engine.executeScheme("(define current-build \"" ~ to!string(choice(n)) ~ "\")");
    }

private:
    DidoEngine _engine;
}

class ArchCombo : ComboBox
{
    this(UIContext context, DidoEngine engine)
    {
        _engine = engine;
        super(context, 
              [ "x86", "x64" ], 
              [ "x86", "x86_64" ],
              "cycle");
    }

    override void onChoice(int n)
    {
        _engine.executeScheme("(define current-arch \"" ~ to!string(choice(n)) ~ "\")");
    }
private:
    DidoEngine _engine;
}


class CompilerCombo : ComboBox
{
    this(UIContext context, DidoEngine engine)
    {
        _engine = engine;
        super(context, 
             [ "DMD", "GDC", "LDC" ], 
             [ "DMD", "GDC", "LDC" ], "cycle");
    }

    override void onChoice(int n)
    {
        _engine.executeScheme("(define current-compiler \"" ~ to!string(choice(n)) ~ "\")");        
    }
private:
    DidoEngine _engine;
}

class BuildButton : UIButton
{
public:
    this(UIContext context, DidoEngine engine)
    {
        super(context, "Build", "build");
        _engine = engine;
    }

    override bool onMousePostClick(int x, int y, int button, bool isDoubleClick)
    {
        _engine.executeScheme("(build current-compiler current-arch current-build)");
        return true;
    }
private:
    DidoEngine _engine;
}

class RunButton : UIButton
{
public:
    this(UIContext context, DidoEngine engine)
    {
        super(context, "Run", "run");
        _engine = engine;
    }

    override bool onMousePostClick(int x, int y, int button, bool isDoubleClick)
    {
        _engine.executeScheme("(run current-compiler current-arch current-build)");
        return true;
    }

private:
    DidoEngine _engine;
}

class DlangOrgButton : UIButton
{
public:
    this(UIContext context)
    {
        super(context, "Home", "dlang");
    }

    override bool onMousePostClick(int x, int y, int button, bool isDoubleClick)
    {
        import std.process;
        browse("http://dlang.org/");
        return true;
    }
}

class DubRegistryButton : UIButton
{
public:
    this(UIContext context)
    {
        super(context, "Registry", "dub");
    }

    override bool onMousePostClick(int x, int y, int button, bool isDoubleClick)
    {
        import std.process;
        browse("http://code.dlang.org/");
        return true;
    }
}