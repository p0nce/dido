// Inspired by lis.py
// (c) Peter Norvig, 2010; See http://norvig.com/lispy.html
module dido.scheme.eval;

import std.string;
import std.variant;

import dido.scheme.types;
import dido.scheme.environment;
import dido.scheme.parser;


/// Execute a string of code.
/// Returns: Text representation of the result expression.
string execute(string code, Environment env)
{
    Atom result = eval(parseExpression(code), env);
    return toString(result);
}

/// Evaluates an expression.
/// Returns: Result of evaluation.
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
        throw new SchemeException(format("Expected %s arguments, got %s", paramList.length, arguments.length));

    for(size_t i = 0; i < paramList.length; ++i)
        values[cast(string)(paramList[i].toSymbol())] = arguments[i];

    Environment newEnv = new Environment(values, closure.env);
    return eval(closure.body_, newEnv);
}
