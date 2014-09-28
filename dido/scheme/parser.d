module dido.scheme.parser;

import std.range;
import std.ascii;

import dido.scheme.types;
import dido.scheme.environment;

enum TokenType
{
    OPEN_PAREN,
    CLOSE_PAREN,
    SYMBOL,
    STRING_LITERAL,
    NUMBER_LITERAL,
    END_OF_INPUT
}

struct Token
{
    TokenType type;
    int line;
    int column;
    string stringValue;
    double numValue;
}

struct Lexer(R) if (isInputRange!R && is(ElementType!R : dchar))
{
public:
    this(R input)
    {
        _input = input;
        _state = State.initial;
        _currentLine = 0;
        _currentColumn = 0;
    }

    Token nextToken()
    {
        string currentString;

        while(true)
        {
            dchar ch = pop();
            bool ascii = isASCII(ch);
            bool control = isControl(ch);
            bool whitespace = isWhite(ch);
            bool punctuation = isPunctuation(ch);
            bool alpha = isAlpha(ch);
            bool digit = isDigit(ch);

            switch(_state) with (State)
            {
                case initial:
                    if (!ascii)
                        throw new SchemeException(format("Non-ASCII character found: '%s'", ch));

                    // skip whitespace
                    if (isWhite(ch))
                        continue;

                    if (control)
                        throw new SchemeException("Control character found");

                    if (ch == '(')
                        return Token(TokenType.OPEN_PAREN, _currentLine, _currentColumn, "", double.nan);
                    else if (ch == ')')
                        return Token(TokenType.CLOSE_PAREN, _currentLine, _currentColumn, "", double.nan);
                    else if (ch == '"')
                    {
                        _state = insideString;
                        currentString = "" ~ ch;
                    }  
                    else if (digit || ch == '.' || ch == '+' || ch == '-')
                    {
                        _state = insideNumber;
                        currentString = "" ~ ch;
                    }
                    else if (alpha || punctuation)
                    {
                        _state = insideSymbol;
                        currentString = "" ~ ch;
                    }                    
                    else
                        assert(false); // all cases have been handled
                    break;

                case insideString:
                    if (ch == '\\')
                        _state = insideStringEscaped;
                    else if (ch == '"')
                        return Token(TokenType.STRING_LITERAL, _currentLine, _currentColumn, currentString, double.nan);
                    else
                        currentString ~= ch;
                    break;

                case insideStringEscaped:
                    if (ch == '\\')
                        currentString ~= '\\';
                    else if (ch == 't')
                        currentString ~= '\t';
                    else if (ch == 'n')
                        currentString ~= '\n';
                    else
                        throw new SchemeException("Unknown escape sequence");
                    _state = insideString;
                    break;

                case insideNumber:

                case insideSymbol:

            }
        }
    }

    dchar peek()
    {
        return _input.front();
    }

    dchar pop()
    {
        if (_input.empty)
            throw new SchemeException("Expected a char, but got end of input");
        dchar ch = _input.front();
        _input.popFront();

        if (ch == "\n")
        {
            _currentLine++;
            _currentColumn = 0;
        }
        else
            _currentColumn++;
        return ch;
    }

    //bool 

private:
    R _input;
    State _state;
    int _currentLine;
    int _currentColumn;

    enum State
    {
        initial,
        insideString,
        insideStringEscaped,
        insideNumber,
        insideSymbol
    }
}

/// Parse a chain of code. Must be a s-expr else SchemeException will be thrown.
/// The string MUST contain only one atom. An input like "1 2 3" won't be accepted.
Atom parse(string code)
{
    return makeNil();
}

unittest
{
    string code = "( 1 \"lol\" test)";
    auto lexer = Lexer(code);
}