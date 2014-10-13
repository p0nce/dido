module dido.panel.menupanel;

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

        addChild(new CompilerCombo(context));        
        addChild(new ArchCombo(context));
        addChild(new BuildCombo(context));
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
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(15, 14, 14, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        //renderer.setColor(255, 255, 255, 255);
        renderer.copy(context.image("dido"), 6, (_position.height - 20) / 2);

    }
}

class BuildCombo : ComboBox
{
    this(UIContext context)
    {
        super(context, [ "debug", "plain", "release", "release-nobounds", "unittest", "profile", "docs", "ddox", "cov", "unittest-cov" ]);
    }

    override void onChoice(int n)
    {
    }
}

class ArchCombo : ComboBox
{
    this(UIContext context)
    {
        super(context, [ "x86", "x86_64" ]);
    }

    override void onChoice(int n)
    {
    }
}


class CompilerCombo : ComboBox
{
    this(UIContext context)
    {
        super(context, [ "DMD", "GDC", "LDC" ]);
    }

    override void onChoice(int n)
    {
    }
}

class BuildButton : UIButton
{
public:
    this(UIContext context, DidoEngine engine)
    {
        super(context, "Build", "build");
        _engine = engine;
    }

    override bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        _engine.executeScheme("build");
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

    override bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        _engine.executeScheme("run");
        return true;
    }

private:
    DidoEngine _engine;
}