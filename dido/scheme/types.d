module dido.scheme.types;

import std.typecons,
       std.conv,
       std.string,
       std.array,
       std.algorithm,
       std.variant;


import dido.scheme.environment;

alias Symbol = Typedef!string;

class Closure
{
public:
    this(Environment env, Atom params, Atom body_)
    {
        this.env = env;
        this.params = params;
        this.body_ = body_;
    }
    Environment env;
    Atom params;
    Atom body_;
}

// An atom is either a string, a double, a symbol, a function (env, params, body) or a list of atoms
alias Atom = Algebraic!(string, double, Symbol, Closure, This[]);


/// The one exception type thrown in this interpreter.
class SchemeException : Exception
{
    public
    {
        @safe pure nothrow this(string message, string file =__FILE__, size_t line = __LINE__, Throwable next = null)
        {
            super(message, file, line, next);
        }
    }
}



Atom makeNil()
{
    Atom[] values = [];
    return Atom(values);
}

Symbol toSymbol(Atom atom)
{
    Symbol failure(Atom x0)
    {
        throw new SchemeException(format("%s is not a symbol", toString(x0)));
    }

    return atom.visit!(
                       (Symbol sym) => sym,
                       (string s) => failure(atom),
                       (double x) => failure(atom),
                       (Atom[] atoms) => failure(atom),
                       (Closure fun) => failure(atom)
                       );
}

bool toBool(Atom atom)
{
    bool failure(Atom x0)
    {
        throw new SchemeException(format("%s cannot be converted to a truth value", toString(x0)));
    }

    return atom.visit!(
                       (Symbol sym) => failure(atom),
                       (string s) => s.length > 0, // "" is falsey
                       (double x) => x != 0, // 0 and NaN is falsey
                       (Atom[] atoms) => failure(atom), // empty list is falsey
                       (Closure fun) => failure(atom)
                       );
}

string toString(Atom atom)
{
    string atomJoiner(Atom[] atoms)
    {
        return map!toString(atoms).joiner(", " ).array.to!string;
    }

    return atom.visit!(
                       (Symbol sym) => cast(string)sym,
                       (string s) => s,
                       (double x) => to!string(x),
                       (Atom[] atoms) => atomJoiner(atoms),
                       (Closure fun) => "#closure"
                           );
}

Closure toClosure(Atom atom)
{
    Closure failure(Atom x0)
    {
        throw new SchemeException(format("%s is not a closure", toString(x0)));
    }

    return atom.visit!(
                       (Symbol sym) => failure(atom),
                       (string s) => failure(atom),
                       (double x) => failure(atom),
                       (Atom[] atoms) => failure(atom),
                       (Closure fun) => fun
                       );
}

Atom[] toList(Atom atom)
{
    Atom[] failure(Atom x0)
    {
        throw new SchemeException(format("%s is not a list", toString(x0)));
    }

    return atom.visit!(
                       (Symbol sym) => failure(atom),
                       (string s) => failure(atom),
                       (double x) => failure(atom),
                       (Atom[] atoms) => atoms,
                       (Closure fun) => failure(atom)
                       );
}