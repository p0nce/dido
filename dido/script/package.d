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

// An atom is either a symbol, a symbol, or a list of atoms
alias Atom = Algebraic!(string, Symbol, This[]);


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



void eval(Atom atom, Environment env)
{
    Atom evalFailure(Atom x0)
    {
        throw new SchemeException(format("%s is not a function", toString(x0)));
    }

    atom.visit!(
        (Symbol sym) => env.find(cast(string)sym).values[cast(string)sym],
        (string s) => atom,
        (Atom[] atoms)
        {
            Atom x0 = atoms[0];

            return x0.visit!(
                (Symbol sym)
                {
                    switch(cast(string)sym)
                    {
                        case "quote":
                        case "if":
                        case "set!":
                        case "define":
                        case "lambda":
                        case "begin":
                        default:
                            return Atom("lol");
                    }
                },
                (string s) => evalFailure(x0),
                (Atom[] atoms) => evalFailure(x0)
            );
        }
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
        (Atom[] atoms) => atomJoiner(atoms)
    );
}
/+
def eval(x, env=global_env):
    "Evaluate an expression in an environment."
    if isa(x, Symbol):             # variable reference
        return env.find(x)[x]
    elif not isa(x, list):         # constant literal
        return x                
    elif x[0] == 'quote':          # (quote exp)
        (_, exp) = x
        return exp
    elif x[0] == 'if':             # (if test conseq alt)
        (_, test, conseq, alt) = x
        return eval((conseq if eval(test, env) else alt), env)
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