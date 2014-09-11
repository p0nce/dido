module dido.config;

import sdlang;

class DidoConfig
{
public:

	string fontFace = "fonts/consola.ttf";
	int fontSize = 14;

    this()
    {
    }

    void read(Tag root)
    {
        foreach(Tag child; root.tags)
        {
            if (child.name == "font")
            {
                foreach(Tag child2; child.tags)
                {
                    if (child2.name == "face")
                        fontFace = child2.values[0].get!string();
                    if (child2.name == "size")
                        fontSize = child2.values[0].get!int();
                }
            }
        }
    }
}