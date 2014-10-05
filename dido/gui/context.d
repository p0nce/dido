module dido.gui.context;

public import gfm.math;
public import gfm.sdl2;
import gfm.image.stb_image;
public import dido.gui.font;
import std.file;

enum UIImage : int
{
    scrollbarN,
    scrollbarS,
    scrollbarE,
    scrollbarW,
    dlang,
    dido
}


class UIContext
{
public:
    this(SDL2 sdl2_, SDL2Renderer renderer_, Font font_)
    {
        renderer = renderer_;
        font = font_;
        sdl2 = sdl2_;

        _surfaces.length = UIImage.max + 1;
        _surfaces[UIImage.scrollbarN] = loadImage(sdl2, imageScrollbarN);
        _surfaces[UIImage.scrollbarS] = loadImage(sdl2, imageScrollbarS);
        _surfaces[UIImage.scrollbarE] = loadImage(sdl2, imageScrollbarE);
        _surfaces[UIImage.scrollbarW] = loadImage(sdl2, imageScrollbarW);
        _surfaces[UIImage.dlang]      = loadImage(sdl2, imageDlang);
        _surfaces[UIImage.dido]       = loadImage(sdl2, imageDido);

        // create textures
        for(int i = 0; i < _surfaces.length; ++i)
            _textures ~= new SDL2Texture(renderer, _surfaces[i]);
    }

    void close()
    {
        foreach(t; _textures)
            t.close();

        foreach(s; _surfaces)
            s.close();
    }

    SDL2 sdl2;
    SDL2Renderer renderer;
    Font font;

    SDL2Texture image(UIImage which)
    {
        return _textures[which];
    }

private:
    SDL2Surface[] _surfaces;
    SDL2Texture[] _textures;
}


static immutable imageScrollbarN = cast(immutable(ubyte[])) import("scrollbarN.png");
static immutable imageScrollbarS = cast(immutable(ubyte[])) import("scrollbarS.png");
static immutable imageScrollbarE = cast(immutable(ubyte[])) import("scrollbarE.png");
static immutable imageScrollbarW = cast(immutable(ubyte[])) import("scrollbarW.png");
static immutable imageDlang      = cast(immutable(ubyte[])) import("dlang.png");
static immutable imageDido      = cast(immutable(ubyte[])) import("dido.png");


SDL2Surface loadImage(SDL2 sdl2, immutable(ubyte[]) imageData)
{
    void[] data = cast(void[])imageData;
    int width, height, components;
    ubyte* decoded = stbi_load_from_memory(data, width, height, components, 4);
    scope(exit) stbi_image_free(decoded);

    // stb_image guarantees that ouput will always have 4 components when asked
    SDL2Surface loaded = new SDL2Surface(sdl2, decoded, width, height, 32, 4 * width,
                                         0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);

    SDL2Surface cloned = loaded.clone(); // to gain pixel ownership
    loaded.close(); // scoped! strangely didn't worked out
    return cloned;
}