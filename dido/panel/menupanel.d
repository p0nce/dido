module dido.panel.menupanel;

import dido.gui;

class MenuPanel : UIElement
{
    this(UIContext context)
    {
        super(context);

        addChild(new CompilerCombo(context));        
        addChild(new ArchCombo(context));
        addChild(new BuildCombo(context));
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _position.max.y = availableSpace.min.y + 8 + 8 + charHeight;

        availableSpace = _position.shrink(4);

        availableSpace.min.x += 16 + 8 + 2;

        child(0).reflow(availableSpace);

        availableSpace.min.x = child(0).position.max.x + 4;
        child(1).reflow(availableSpace);

        availableSpace.min.x = child(1).position.max.x + 4;
        child(2).reflow(availableSpace);
    }

    override void preRender(SDL2Renderer renderer)
    {
        renderer.setColor(15, 14, 14, 255);
        renderer.fillRect(0, 0, _position.width, _position.height);

        //renderer.setColor(255, 255, 255, 255);
        renderer.copy(context.image(UIImage.dido), 6, (_position.height - 20) / 2);

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