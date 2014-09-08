module app;

import std.typecons;
import std.process;
import std.stdio;
import std.path;
import std.string;
import std.file;
import std.json;

import dido;

void main(string[] args)
{
    string[] inputFiles;

    for (int argIndex = 1; argIndex < args.length; ++argIndex)
    {
        string arg = args[argIndex];
        inputFiles ~= arg;
    }

    if (inputFiles.length == 0)
    {
        if (exists("dub.json"))
            inputFiles ~= "dub.json";
        if (exists("package.json"))
            inputFiles ~= "package.json";

        auto dubResult = execute(["dub", "describe", "--nodeps"]);

        if (dubResult.status != 0)
            throw new Exception(format("dub returned %s", dubResult.status));

        JSONValue description = parseJSON(dubResult.output);

        foreach (pack; description["packages"].array())
        {
            string packpath = pack["path"].str;

            foreach (file; pack["files"].array())
            {
                string filepath = file["path"].str();
                inputFiles ~= buildPath(packpath, filepath);
            }
        }
    }

    auto app = scoped!App(inputFiles);
    app.mainLoop();
}
