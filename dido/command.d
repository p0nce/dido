module dido.command;


// Editor commands (abstracted for macros)

enum CommandType
{
    MOVE_LEFT,
    MOVE_RIGHT,
    MOVE_UP,
    MOVE_DOWN,
    PAGE_UP,
    PAGE_DOWN,
    MOVE_LINE_END,
    MOVE_LINE_BEGIN,
    EXTEND_SELECTION_UP,
    EXTEND_SELECTION_DOWN,
    TOGGLE_FULLSCREEN,
    ENTER_COMMANDLINE_MODE, 
    ESCAPE, 
    RETURN,
    INSERT_CHAR,
    DELETE,
    BACKSPACE,
    ROTATE_NEXT_BUFFER,
    ROTATE_PREVIOUS_BUFFER,
    UNDO,
    REDO
}

struct Command
{
    this(CommandType type_)
    {
        type = type_;
    }

    this(CommandType type_, bool shift_)
    {
        type = type_;
        shift = shift_;
    }

    this(CommandType type_, dchar ch_)
    {
        type = type_;
        ch = ch_;
    }

    CommandType type;
    dchar ch;
    bool shift = false;    
}


