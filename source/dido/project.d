module dido.project;

import std.path;
import std.string;
import std.file;
import std.json;
import std.process;

import dido.buffer.buffer;

// Model
class Project
{
private:
    string _absPath; // path of dub.json

    string _mainPackage;
    
    Buffer[] _buffers;
    int _bufferSelect;

    ProjectPackage[] _packages;

public:
    this(string absPath)
    {
        _absPath = absPath;
        getDubDescription();

        foreach (ProjectPackage projectPackage; _packages)
        {
            foreach (ref path; projectPackage.files)
            {
                Buffer buf = new Buffer(path);
                _buffers ~= buf;
            }
        }        

        // create an empty buffer if no file provided
        if (_buffers.length == 0)
        {
            Buffer buf = new Buffer;
            _buffers ~= buf;
        }

        _bufferSelect = 0;
    }

    int numBuffers()
    {
        return cast(int)(_buffers.length);
    }

    // change current edited buffer, but not the project
    void setCurrentBuffer(int bufferSelect)
    {
        _bufferSelect = bufferSelect;
    }

    void nextBuffer()
    {
        setCurrentBuffer( (_bufferSelect + 1) % cast(int) _buffers.length );
    }

    void previousBuffer()
    {
        setCurrentBuffer( (_bufferSelect + cast(int) _buffers.length - 1) % cast(int) _buffers.length );
    }

    int bufferSelect(int x)
    {
        return _bufferSelect = x;
    }

    int bufferSelect()
    {
        return _bufferSelect;
    }

    ref Buffer[] buffers()
    {
        return _buffers;
    }

    Buffer currentBuffer()
    {
        return _buffers[_bufferSelect];
    }

private:

    void getDubDescription()
    {      
        // change directory
        string oldDir = getcwd();
        chdir(dirName(_absPath));
        scope(exit)
            chdir(oldDir);

        auto dubResult = execute(["dub", "describe"]);

        if (dubResult.status != 0)
            throw new Exception(format("dub returned %s", dubResult.status));

        JSONValue description = parseJSON(dubResult.output);

        _mainPackage = description["mainPackage"].str;

        foreach (pack; description["packages"].array())
        {
            ProjectPackage projectPackage = new ProjectPackage;

            projectPackage.name = pack["name"].str;
            projectPackage.absPath = pack["path"].str;

            foreach (file; pack["files"].array())
            {
                string filepath = file["path"].str();

                // only add files dido can render
                if (filepath.endsWith(".d") || filepath.endsWith(".json") || filepath.endsWith(".res"))
                {
                    projectPackage.files ~= buildPath(projectPackage.absPath, filepath);
                }
            }

            _packages ~= projectPackage;
        }
    }
}


class ProjectPackage
{
    string absPath;
    string name;
    string[] files;
}