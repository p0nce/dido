module dido.builder;

import core.thread;

import std.array;
import std.conv;
import std.string;
import std.process;


import dido.engine;
import dido.panel.outputpanel;

class Builder
{
public:
    this(DidoEngine engine)
    {
        _engine = engine;
    }

    void startBuild(string compiler, string arch, string build)
    {
        stopBuild();
        if (_state != State.initial)
            return;

        _state = State.building;
        _buildThread = new BuildThread(this, BuildAction.build, compiler, arch, build);
        _buildThread.start();
    }

    void startRun(string compiler, string arch, string build)
    {
        stopBuild();
        if (_state != State.initial)
            return;

        _state = State.running;
        _buildThread = new BuildThread(this, BuildAction.run, compiler, arch, build);
        _buildThread.start();
    }

    void startTest(string compiler, string arch, string build)
    {
        stopBuild();
        if (_state != State.initial)
            return;

        _state = State.building;
        _buildThread = new BuildThread(this, BuildAction.test, compiler, arch, build);
        _buildThread.start();
    }

    void stopBuild()
    {
        if (_state == State.initial)
            return;

        _state = State.initial;
        _buildThread.signalStop();
        _buildThread.join();
    }

private:
    enum State
    {
        initial,
        building,
        running
    }
    shared State _state = State.initial;

    DidoEngine _engine;

    BuildThread _buildThread;
}

enum BuildAction
{
    build,
    test,
    run
}

class BuildThread : Thread
{
    this(Builder builder, BuildAction action, string compiler, string arch, string build)
    {
        _action = action;
        _builder = builder;

        _compiler = compiler;
        _arch = arch;
        _build = build;
        super( &run );
    }

    void signalStop()
    {
        synchronized(this)
            _stop = true;
    }

private:
    Builder _builder;
    BuildAction _action;
    bool _stop = false;
    string _compiler;
    string _arch;
    string _build;

    void run()
    {
        string command;
        final switch(_action) with (BuildAction)
        {
            case BuildAction.run: command = "run"; break;
            case BuildAction.build: command = "build"; break;
            case BuildAction.test: command = "test"; break;
        }

        auto commands = ["dub", command, "--compiler", _compiler, "--arch", _arch, "--build", _build];
        string asOneLine = "$" ~ std.array.join(commands, " ");

        _builder._engine.logMessage(LineType.COMMAND, to!dstring(asOneLine));


        auto pipes = pipeProcess(["dub", command], Redirect.stdout | Redirect.stderr);
        scope(exit)
        {
            int exitCode = wait(pipes.pid);
            if (exitCode == 0)
                _builder._engine.logMessage(LineType.RESULT, "Done."d);
            else
            {
                dstring msg = to!dstring(format("dub returned %s", exitCode));
                _builder._engine.logMessage(LineType.ERROR, msg);
            }
        }

        // pipe stdout to output window
        foreach (line; pipes.stdout.byLine)
        {
            synchronized // polling exit condition
            {
                if (_stop)
                {
                    _builder._engine.greenMessage("Build was interrupted.");
                    return;
                }
            }
            _builder._engine.logMessage(LineType.EXTERNAL, to!dstring(line));
        }

        // pipe stderr to output window
        foreach (line; pipes.stderr.byLine)
        {
            synchronized // polling exit condition
            {
                if (_stop)
                {
                    _builder._engine.greenMessage("Build was interrupted.");
                    return;
                }
            }
            _builder._engine.logMessage(LineType.EXTERNAL, to!dstring(line));
        }
    }
}
