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

// An atom is either a string, a double, a symbol, or a list of atoms
alias Atom = Algebraic!(string, double, Symbol, This[]);


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
                        case "begin":
                        default:
/*
                            // evaluate alls
                            Atom[] evaluated;
                            foreach(atom; atoms)  = atoms.map!eval(
*/

                            return makeNil();
                    }
                },
                (string s) => evalFailure(x0),
                (double x) => evalFailure(x0),
                (Atom[] atoms) => evalFailure(x0)
            );
        }
    );   
    return result;
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
        (Atom[] atoms) => failure(atom)
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
        (Atom[] atoms) => failure(atom) // empty list is falsey
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
        (Atom[] atoms) => atomJoiner(atoms)
    );
}

/+

    elif x[0] == 'set!':           # (set! var exp)
        (_, var, exp) = x
        env.find(var)[var] = eval(exp, env)
    elif x[0] == 'define':         # (define var exp)
        (_, var, exp) = x
        env[var] = eval(exp, env)
    elif x[0] == 'lambda':         # (lambda (var*) exp)
        (_, vars, exp) = x
        return lambda *args: eval(exp, Env(vars, args, env))
    elif x[0] == 'begin':          # (begin exp*)
        for exp in x[1:]:
            val = eval(exp, env)
        return val
    else:                          # (proc exp*)
        exps = [eval(exp, env) for exp in x]
        proc = exps.pop(0)
        return proc(*exps)

################ parse, read, and user interaction

def read(s):
    "Read a Scheme expression from a string."
    return read_from(tokenize(s))

parse = read

def tokenize(s):
    "Convert a string into a list of tokens."
    return s.replace('(',' ( ').replace(')',' ) ').split()

def read_from(tokens):
    "Read an expression from a sequence of tokens."
    if len(tokens) == 0:
        raise SyntaxError('unexpected EOF while reading')
    token = tokens.pop(0)
    if '(' == token:
        L = []
        while tokens[0] != ')':
            L.append(read_from(tokens))
        tokens.pop(0) # pop off ')'
        return L
    elif ')' == token:
        raise SyntaxError('unexpected )')
    else:
        return atom(token)

def atom(token):
    "Numbers become numbers; every other token is a symbol."
    try: return int(token)
    except ValueError:
        try: return float(token)
        except ValueError:
            return Symbol(token)

+/