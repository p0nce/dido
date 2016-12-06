module dido.buffer.analysis;

//import std.d.lexer;

/+
class Analysis
{
    this(string filename, string source)
    {
        _filename = filename;
        _stringCache = StringCache(StringCache.defaultBucketCount);
    }

    void parse(string filemane, string source)
    {
        _tokens = getTokensForParser( cast(ubyte[]) source, LexerConfig(filemane, StringBehavior.source), &_stringCache);
    }

private:
    string _filename;
    StringCache _stringCache;
    const(Token)[] _tokens;
}+/