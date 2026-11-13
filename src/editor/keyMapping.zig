const Editor = @import("editor.zig");

pub const NONE: Editor.Key = 0x00;
pub const SCROLL_UP: Editor.Key = 0x01;
pub const SCROLL_DOWN: Editor.Key = 0x02;
pub const COPY: Editor.Key = 0x03;
pub const NEWLINE: Editor.Key = 0x0A;
pub const ENTER: Editor.Key = 0x0D;
pub const ARROW_UP: Editor.Key = 0x11;
pub const ARROW_DOWN: Editor.Key = 0x12;
pub const ARROW_LEFT: Editor.Key = 0x13;
pub const ARROW_RIGHT: Editor.Key = 0x14;
pub const MOUSE_CLICK: Editor.Key = 0x15;
pub const PASTE: Editor.Key = 0x16;
pub const ESC: Editor.Key = 0x1B;
pub const MOUSE_DRAG: Editor.Key = 0x1C;
pub const MOUSE_RELEASE: Editor.Key = 0x1D;
pub const SPACE: Editor.Key = 0x20;
pub const BACKSPACE: Editor.Key = 0x7F;

pub const KeyEvent = struct {
    key: Editor.Key,
    col: usize = 0,
    row: usize = 0,
};
