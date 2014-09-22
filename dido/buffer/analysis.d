module dido.buffer.analysis;

import std.d.lexer;


class Analysis
{
    this(string filemane, string source)
    {
        stringCache = new StringCache(StringCache.defaultBucketCount);
        tokens = getTokensForParser( cast(ubyte[]) source, LexerConfig(filemane, StringBehavior.source), stringCache);
    }
}