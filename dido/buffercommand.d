module dido.buffercommand;

import dido.selection;

enum BufferCommandType
{
    CHANGE_CHARS, // edit one text area
    BARRIER       // anchors for undo/redo
}

struct BufferCommand
{
    BufferCommandType type;
    Selection sel;
    dstring oldContent; // content of selection before applying this BufferCommand
    dstring newContent; // content of selection after applying this BufferCommand
}

BufferCommand barrierCommand()
{
    return BufferCommand(BufferCommandType.BARRIER, Selection.init, dstring.init, dstring.init);
}