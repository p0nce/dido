module app;

import std.typecons;

import dido;


void main(string[] args)
{
    string[] inputFiles;

    for (int argIndex = 1; argIndex < args.length; ++argIndex)
    {
        string arg = args[argIndex];
        inputFiles ~= arg;
    }  

    auto app = scoped!App("dido/app.d");
    app.mainLoop();
}
