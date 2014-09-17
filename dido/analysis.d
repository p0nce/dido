module dido.analysis;

import std.algorithm;
import std.string;
import std.array;
import std.file;

import d.context;
import d.location;
import d.ast.expression;
import d.semantic.semantic;
import d.semantic.evaluator;

import d.ir.expression;

final class Analysis 
{
public:

    this(string[] includePaths_)
    {
        includePaths = includePaths_;
        context = new Context();
        evaluator = new DummyEvaluator();
        semantic = new SemanticPass(context, evaluator, &getFileSource);
    }

    void compile(string filename) 
    {
        auto packages = filename[0 .. $ - 2].split("/").map!(p => context.getName(p)).array();
        modules ~= semantic.add(new FileSource(filename), packages);
    }

    FileSource getFileSource(Name[] packages) 
    {
        auto filename = "/" ~ packages.map!(p => p.toString(context)).join("/") ~ ".d";

        foreach(path; includePaths) 
        {
            auto fullpath = path ~ filename;
            if(exists(fullpath)) 
            {
                return new FileSource(fullpath);
            }
        }
        assert(0, "filenotfoundmalheur ! " ~ filename);
    }

private:
    string[] includePaths;
    Context context;
    SemanticPass semantic;
    Module[] modules;
    DummyEvaluator evaluator;
}

final class DummyEvaluator : Evaluator
{
    override CompileTimeExpression evaluate(Expression e)
    {
        return new BooleanLiteral(e.location, false);
    }
}