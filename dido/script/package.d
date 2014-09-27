// Inspired by lis.py
// (c) Peter Norvig, 2010; See http://norvig.com/lispy.html

module dido.script;

import std.algorithm,
       std.array,
       std.conv,
       std.string,
       std.typecons,
       std.variant;
       

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

class Environment
{
    this(Atom[string] values_, Environment outer_ = null)
    {
        values = values_;
        outer = outer_;
    }

    Environment outer;
    Atom[string] values;

    // Find the innermost Environment where var appears.
    Environment find(string var)
    {
        if (var in values)
            return this;
        else
        {
            if (outer is null)
                return null;
            return outer.find(var);
        }
    }
    ref Atom findSymbol(Symbol symbol)
    {
        string s = cast(string)symbol;
        Environment env = find(s);
        if (env is null)
            throw new SchemeException(format("Variable '%d' is not defined", s));

        return env.values[s];
    }
}

__gshared Environment globalEnv;

shared static this()
{
    Atom[string] defaultValues;

    /*
    def add_globals(env):
    "Add some Scheme standard procedures to an environment."
    import math, operator as op
    env.update(vars(math)) # sin, sqrt, ...
    env.update(
    {'+':op.add, '-':op.sub, '*':op.mul, '/':op.div, 'not':op.not_,
    '>':op.gt, '<':op.lt, '>=':op.ge, '<=':op.le, '=':op.eq, 
    'equal?':op.eq, 'eq?':op.is_, 'length':len, 'cons':lambda x,y:[x]+y,
    'car':lambda x:x[0],'cdr':lambda x:x[1:], 'append':op.add,  
    'list':lambda *x:list(x), 'list?': lambda x:isa(x,list), 
    'null?':lambda x:x==[], 'symbol?':lambda x: isa(x, Symbol)})
    return env

    */

    globalEnv = new Environment(defaultValues, null);
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

Atom eval(Atom atom, Environment env)
{
    Atom evalFailure(Atom x0)
    {
        throw new SchemeException(format("%s is not a function", toString(x0)));
    }

    Atom result = atom.visit!(
        (Symbol sym) => env.findSymbol(sym),
        (string s) => atom,
        (double x) => atom,
        (Closure fun) => evalFailure(atom),
        (Atom[] atoms)
        {
            // empty list evaluate to itself
            if (atoms.length == 0)
                return atom;

            Atom x0 = atoms[0];

            return x0.visit!(
                (Symbol sym)
                {
                    switch(cast(string)sym)
                    {
                        // Special forms
                        case "quote": 
                            if (atoms.length < 2)
                                throw new SchemeException("Empty quote");
                            return Atom(atoms[1..$]);

                        case "if":
                            if (atoms.length != 4)
                                throw new SchemeException("Invalid if expression, should be (if test-expr then-expr else-expr)");
                            if (toBool(eval(atoms[1], env)))
                                return eval(atoms[2], env);
                            else
                                return eval(atoms[3], env);

                        case "set!":
                            if (atoms.length != 3)
                                throw new SchemeException("Invalid set! expression, should be (set! var exp)");
                            env.findSymbol(atoms[1].toSymbol) = eval(atoms[2], env);
                            return makeNil();

                        case "define":
                            if (atoms.length != 3)
                                throw new SchemeException("Invalid define expression, should be (define var exp)");
                            env.values[cast(string)(toSymbol(atoms[1]))] = eval(atoms[2], env);
                            return makeNil();

                        case "lambda":
                            if (atoms.length != 3)
                                throw new SchemeException("Invalid lambda expression, should be (lambda params body)");
                            return Atom(new Closure(env, atoms[1], atoms[2]));

                        case "begin":
                            if (atoms.length == 3)
                                return atom;
                            Atom lastValue;
                            foreach(ref Atom x; atoms[1..$])
                                lastValue = eval(x, env);
                            return lastValue;

                        default:
                            // function call
                            Atom[] values;
                            foreach(ref Atom x; atoms[1..$])
                                values ~= eval(x, env);
                            return apply(eval(atoms[0], env), values);
                    }
                },
                (string s) => evalFailure(x0),
                (double x) => evalFailure(x0),
                (Atom[] atoms) => evalFailure(x0),
                (Closure fun) => evalFailure(x0)
            );
        }
    );   
    return result;
}


Atom apply(Atom atom, Atom[] arguments)
{
    auto closure = atom.toClosure();

    // build new environment
    Atom[] paramList = toList(closure.params);
    Atom[string] values;

    if (paramList.length != arguments.length)
        throw new SchemeException(format("Exoected %s arguments, got %s", paramList.length, arguments.length));

    for(size_t i = 0; i < paramList.length; ++i)
        values[cast(string)(paramList[i].toSymbol())] = arguments[i];

    Environment newEnv = new Environment(values, closure.env);
    return eval(closure.body_, newEnv);
}