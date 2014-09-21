module dido.buffer.buffercommand;

import dido.buffer.selection;

enum BufferCommandType
{
    CHANGE_CHARS, // edit one text area
    BARRIER,      // anchors for undo/redo, saves all selections location
    SAVE_SELECTIONS

}

struct ChangeCharsCommand
{
    Selection oldSel;
    Selection newSel;
    dstring oldContent; // content of selection before applying this BufferCommand
    dstring newContent; // content of selection after applying this BufferCommand
}

struct BarrierCommand
{
}

struct SaveSelectionsCommand
{
    Selection[] selections;
}

struct BufferCommand
{
    BufferCommandType type;
    union
    {
        ChangeCharsCommand changeChars;
        BarrierCommand barrier;
        SaveSelectionsCommand saveSelections;
    }   
}

BufferCommand barrierCommand()
{
    BufferCommand command;
    command.type = BufferCommandType.BARRIER;
    return command;
}

BufferCommand saveSelectionsCommand(Selection[] selectionToSave)
{
    BufferCommand command;
    command.type = BufferCommandType.SAVE_SELECTIONS;
    command.saveSelections.selections = selectionToSave.dup;
    return command;
}

BufferCommand changeCharsCommand(Selection oldSel,
                                 Selection newSel,
                                 dstring oldContent,
                                 dstring newContent)
{
    BufferCommand command;
    command.type = BufferCommandType.CHANGE_CHARS;
    command.changeChars = ChangeCharsCommand(oldSel, newSel, oldContent.dup, newContent.dup);
    return command;
}
