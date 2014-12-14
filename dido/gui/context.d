module dido.gui.context;

public import gfm.math;
public import gfm.sdl2;
import gfm.image.stb_image;
public import dido.gui.font;
import std.file;

import dido.gui.element;

class UIContext
{
public:
    this(SDL2 sdl2_, SDL2Renderer renderer_, Font font_)
    {
        renderer = renderer_;
        font = font_;
        
        
        sdl2 = sdl2_;
    }

    void close()
    {
        foreach(t; _textures)
            t.close();

        foreach(s; _surfaces)
            s.close();
    }

    void addImage(string name, immutable(ubyte[]) data)
    {
        _surfaces[name] = loadImage(sdl2, data);
        auto texture = new SDL2Texture(renderer, _surfaces[name]);
        texture.setAlphaMod(255);
        texture.setColorMod(255, 255, 255);
        _textures[name] = texture;
    }

    SDL2 sdl2;
    SDL2Renderer renderer;
    Font font;
    UIElement dragged = null; // current dragged element

    SDL2Texture image(string name)
    {
        return _textures[name];
    }

    void beginDragging(UIElement element)
    {
        stopDragging();

        // Uncomment this once SDL_CaptureMouse is in Derelict
        // SDL_CaptureMouse(SDL_TRUE);

        dragged = element;
        dragged.onBeginDrag();
    }

    void stopDragging()
    {
        if (dragged !is null)
        {
            dragged.onStopDrag();
            dragged = null;

            // Uncomment this once SDL_CaptureMouse is in Derelict
            // SDL_CaptureMouse(SDL_FALSE);
        }
    }

private:
    SDL2Surface[string] _surfaces;
    SDL2Texture[string] _textures;

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
}




