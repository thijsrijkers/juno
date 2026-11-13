//! Core modal editing engine (normal / insert / visual, motions, buffers)
const std = @import("std");
const mapping = @import("keyMapping.zig");
const canvasContent = @import("../canvas/canvas.zig");
const fileContent = @import("../file/fileContent.zig");
const state = @import("./state.zig");
const undoState = @import("../canvas/state.zig");
const fileSearch = @import("../file/fileSearch.zig");
const contentSearch = @import("../file/contentSearch.zig");
const bufferSearch = @import("../file/bufferSearch.zig");
const fileTree = @import("../file/fileTree.zig");
const selection = @import("./selection.zig");
const clipboard = @import("./clipboard.zig");

pub const Editor = struct {
    io: std.Io,
    x: usize = 0,
    y: usize = 0,
    running: bool = true,
    insert: bool = false,
    leader: bool = false,
    pending: ?usize = null,
    lastState: state.State = .Normal,
    filePicker: fileSearch.Picker = .{},
    contentPicker: contentSearch.Picker = .{},
    bufferPicker: bufferSearch.Picker = .{},
    tree: fileTree.Tree = .{},
    selection: ?selection.Selection = null,
    clipboard: std.ArrayList(u8) = .empty,
};

pub const Key = u8;

pub fn init(io: std.Io) Editor {
    return Editor{
        .io = io,
    };
}

pub fn insertChar(
    editor: *Editor,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
    ch: u8,
) !void {
    if (canvas.lines.len == 0) return;
    const line = &canvas.lines[editor.y];
    const col = @min(editor.x, line.items.len);
    try line.insert(allocator, col, ch);
    editor.x = col + 1;
}

pub fn deleteCharBackward(
    editor: *Editor,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    if (canvas.lines.len == 0) return;

    if (editor.x == 0) {
        // Nothing to join if we're already on the first line.
        if (editor.y == 0) return;

        const prev_len = canvas.lines[editor.y - 1].items.len;
        // Append current line's contents onto the previous line.
        try canvas.lines[editor.y - 1].appendSlice(allocator, canvas.lines[editor.y].items);
        canvas.lines[editor.y].deinit(allocator);

        // Shift everything after the removed line up by one.
        var new_lines = try allocator.alloc(std.ArrayList(u8), canvas.lines.len - 1);
        @memcpy(new_lines[0..editor.y], canvas.lines[0..editor.y]);
        @memcpy(new_lines[editor.y..], canvas.lines[editor.y + 1 ..]);
        allocator.free(canvas.lines);
        canvas.lines = new_lines;

        allocator.free(canvas.grid.rows);
        canvas.grid = try canvasContent.buildGrid(allocator, canvas.lines);

        editor.y -= 1;
        editor.x = prev_len;
        return;
    }

    const line = &canvas.lines[editor.y];
    const clamped_x = @min(editor.x, line.items.len);
    const col = clamped_x - 1;
    _ = line.orderedRemove(col);
    editor.x = col;
}

pub fn newlineAtCursor(
    editor: *Editor,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    const line = &canvas.lines[editor.y];
    const col = @min(editor.x, line.items.len);
    var rest = std.ArrayList(u8).empty;
    try rest.appendSlice(allocator, line.items[col..]);
    line.shrinkRetainingCapacity(col);

    var new_lines = try allocator.alloc(std.ArrayList(u8), canvas.lines.len + 1);
    @memcpy(new_lines[0 .. editor.y + 1], canvas.lines[0 .. editor.y + 1]);
    new_lines[editor.y + 1] = rest;
    @memcpy(new_lines[editor.y + 2 ..], canvas.lines[editor.y + 1 ..]);
    allocator.free(canvas.lines);
    canvas.lines = new_lines;

    allocator.free(canvas.grid.rows);
    canvas.grid = try canvasContent.buildGrid(allocator, canvas.lines);

    editor.y += 1;
    editor.x = 0;
}

fn copySelection(editor: *Editor, allocator: std.mem.Allocator, canvas: *canvasContent.CanvasContent) !void {
    const sel = editor.selection orelse return;
    try selection.copy(sel, allocator, canvas, &editor.clipboard);
    try clipboard.write(editor.io, editor.clipboard.items);
}

fn deleteSelection(editor: *Editor, allocator: std.mem.Allocator, canvas: *canvasContent.CanvasContent) !void {
    const sel = editor.selection orelse return;
    const cursor = try selection.delete(sel, allocator, canvas);
    editor.x = cursor.x;
    editor.y = cursor.y;
    editor.selection = null;
}

fn paste(editor: *Editor, allocator: std.mem.Allocator, canvas: *canvasContent.CanvasContent) !void {
    try clipboard.read(allocator, editor.io, &editor.clipboard);
    if (editor.clipboard.items.len == 0) return;
    try deleteSelection(editor, allocator, canvas);
    for (editor.clipboard.items) |ch| switch (ch) {
        '\n' => try newlineAtCursor(editor, allocator, canvas),
        '\r' => {},
        else => try insertChar(editor, allocator, canvas, ch),
    };
}

fn clampColumn(editor: *Editor, canvas: *canvasContent.CanvasContent) void {
    if (canvas.lines.len == 0) {
        editor.x = 0;
        return;
    }
    editor.x = @min(editor.x, canvas.lines[editor.y].items.len);
}

fn moveLeft(editor: *Editor, canvas: *canvasContent.CanvasContent, amount: usize) void {
    editor.x -|= amount;
    clampColumn(editor, canvas);
}

fn moveRight(editor: *Editor, canvas: *canvasContent.CanvasContent, amount: usize) void {
    if (canvas.lines.len == 0) return;
    editor.x = @min(editor.x + amount, canvas.lines[editor.y].items.len);
}

fn moveUp(editor: *Editor, canvas: *canvasContent.CanvasContent, amount: usize) void {
    if (canvas.lines.len == 0) return;
    editor.y -|= amount;
    clampColumn(editor, canvas);
}

fn moveDown(editor: *Editor, canvas: *canvasContent.CanvasContent, amount: usize) void {
    if (canvas.lines.len == 0) return;
    editor.y = @min(editor.y + amount, canvas.lines.len - 1);
    clampColumn(editor, canvas);
}

fn jumpToLine(editor: *Editor, canvas: *canvasContent.CanvasContent, line: usize) void {
    if (canvas.lines.len == 0) return;
    editor.y = @min(line -| 1, canvas.lines.len - 1);
    clampColumn(editor, canvas);
}

fn moveToClick(editor: *Editor, canvas: *canvasContent.CanvasContent, event: mapping.KeyEvent) void {
    if (canvas.lines.len == 0) return;
    const gutterWidth = canvas.grid.numberWidth + 3; // "N | "
    editor.y = @min((event.row -| (canvasContent.topBar + 1)) + canvas.scrollOffset, canvas.lines.len - 1);
    editor.x = @min((event.col -| 1) -| fileTree.offset(&editor.tree) -| gutterWidth, canvas.lines[editor.y].items.len);
}

fn takeCount(editor: *Editor) usize {
    const count = editor.pending orelse 1;
    editor.pending = null;
    return @max(count, 1);
}

fn appendDigit(editor: *Editor, key: Key) void {
    editor.pending = (editor.pending orelse 0) * 10 + (key - '0');
}

fn reset(editor: *Editor) void {
    editor.insert = false;
    editor.leader = false;
    editor.pending = null;
    editor.selection = null;
    fileSearch.close(&editor.filePicker);
    contentSearch.close(&editor.contentPicker);
    bufferSearch.close(&editor.bufferPicker);
    editor.lastState = .Normal;
}

fn enterSearch(editor: *Editor) void {
    editor.leader = false;
    editor.pending = null;
    editor.lastState = .Search;
}

fn handleInsertKey(
    editor: *Editor,
    allocator: std.mem.Allocator,
    key: Key,
    canvas: *canvasContent.CanvasContent,
) !void {
    switch (key) {
        mapping.COPY => return copySelection(editor, allocator, canvas),
        mapping.PASTE => return paste(editor, allocator, canvas),
        else => {},
    }
    editor.selection = null;

    switch (key) {
        mapping.ESC => reset(editor),
        mapping.ENTER, mapping.NEWLINE => try newlineAtCursor(editor, allocator, canvas),
        mapping.BACKSPACE => try deleteCharBackward(editor, allocator, canvas),
        mapping.ARROW_LEFT => moveLeft(editor, canvas, 1),
        mapping.ARROW_RIGHT => moveRight(editor, canvas, 1),
        mapping.ARROW_UP, mapping.SCROLL_UP => moveUp(editor, canvas, 1),
        mapping.ARROW_DOWN, mapping.SCROLL_DOWN => moveDown(editor, canvas, 1),
        else => {
            if (std.ascii.isPrint(key)) {
                try insertChar(editor, allocator, canvas, key);
            }
        },
    }
}

fn handleLeaderKey(
    editor: *Editor,
    allocator: std.mem.Allocator,
    key: Key,
    canvas: *canvasContent.CanvasContent,
) !void {
    switch (key) {
        mapping.ESC => reset(editor),
        mapping.SPACE => {
            try bufferSearch.open(&editor.bufferPicker, canvas);
            enterSearch(editor);
        },
        'f' => {
            try fileSearch.open(&editor.filePicker, editor.io);
            enterSearch(editor);
        },
        'g' => {
            try contentSearch.open(&editor.contentPicker, editor.io);
            enterSearch(editor);
        },
        'w' => {
            _ = try fileContent.writeFileContent(allocator, editor, canvas);
            editor.leader = false;
            editor.pending = null;
            editor.lastState = .Saved;
        },
        't' => {
            try fileTree.toggle(&editor.tree, editor.io);
            editor.leader = false;
            editor.pending = null;
            editor.lastState = .Normal;
        },
        'q' => editor.running = false,
        '0'...'9' => appendDigit(editor, key),
        mapping.ENTER, mapping.NEWLINE => {
            if (editor.pending) |line| jumpToLine(editor, canvas, line);
            editor.leader = false;
            editor.pending = null;
            editor.lastState = .Normal;
        },
        else => {},
    }
}

pub fn deleteLine(
    editor: *Editor,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    if (canvas.lines.len == 0) return;

    if (canvas.lines.len == 1) {
        canvas.lines[0].clearRetainingCapacity();
        editor.x = 0;
        return;
    }

    canvas.lines[editor.y].deinit(allocator);

    var new_lines = try allocator.alloc(std.ArrayList(u8), canvas.lines.len - 1);
    @memcpy(new_lines[0..editor.y], canvas.lines[0..editor.y]);
    @memcpy(new_lines[editor.y..], canvas.lines[editor.y + 1 ..]);
    allocator.free(canvas.lines);
    canvas.lines = new_lines;

    allocator.free(canvas.grid.rows);
    canvas.grid = try canvasContent.buildGrid(allocator, canvas.lines);

    editor.y = @min(editor.y, canvas.lines.len - 1);
    clampColumn(editor, canvas);
}

pub fn handleKey(
    editor: *Editor,
    allocator: std.mem.Allocator,
    event: mapping.KeyEvent,
    canvas: *canvasContent.CanvasContent,
) !void {
    const key = event.key;

    if (editor.filePicker.active)
        return fileSearch.handleKey(&editor.filePicker, editor, allocator, key, canvas);
    if (editor.contentPicker.active)
        return contentSearch.handleKey(&editor.contentPicker, editor, allocator, key, canvas);
    if (editor.bufferPicker.active)
        return bufferSearch.handleKey(&editor.bufferPicker, editor, allocator, key, canvas);

    if (key == mapping.MOUSE_CLICK) {
        if (event.row <= canvasContent.topBar) return;
        if (event.col <= fileTree.offset(&editor.tree))
            return fileTree.handleClick(&editor.tree, editor, allocator, event.row, canvas);
        moveToClick(editor, canvas, event);
        const point: selection.Point = .{ .x = editor.x, .y = editor.y };
        editor.selection = .{ .start = point, .end = point };
        return;
    }

    if (key == mapping.MOUSE_DRAG) {
        if (editor.selection) |*sel| if (sel.active) {
            moveToClick(editor, canvas, event);
            sel.end = .{ .x = editor.x, .y = editor.y };
        };
        return;
    }

    if (key == mapping.MOUSE_RELEASE) {
        if (editor.selection) |*sel| {
            sel.active = false;
            if (selection.isEmpty(sel.*)) editor.selection = null;
        }
        return;
    }

    if (editor.insert) return handleInsertKey(editor, allocator, key, canvas);
    if (editor.leader) return handleLeaderKey(editor, allocator, key, canvas);

    switch (key) {
        'i' => {
            try undoState.pushPreviousState(allocator, canvas);
            editor.insert = true;
            editor.pending = null;
            editor.lastState = .Editing;
        },
        '0'...'9' => appendDigit(editor, key),
        'c', mapping.COPY => {
            editor.pending = null;
            try copySelection(editor, allocator, canvas);
        },
        'v', mapping.PASTE => {
            editor.pending = null;
            try undoState.pushPreviousState(allocator, canvas);
            try paste(editor, allocator, canvas);
        },
        'd' => {
            editor.pending = null;
            try undoState.pushPreviousState(allocator, canvas);
            if (editor.selection != null)
                try deleteSelection(editor, allocator, canvas)
            else
                try deleteLine(editor, allocator, canvas);
        },
        'u' => {
            editor.pending = null;
            editor.selection = null;
            try undoState.undo(allocator, canvas);
            editor.y = @min(editor.y, canvas.lines.len -| 1);
            clampColumn(editor, canvas);
        },
        'h', mapping.ARROW_LEFT => moveLeft(editor, canvas, takeCount(editor)),
        'j', mapping.ARROW_DOWN => moveDown(editor, canvas, takeCount(editor)),
        'k', mapping.ARROW_UP => moveUp(editor, canvas, takeCount(editor)),
        'l', mapping.ARROW_RIGHT => moveRight(editor, canvas, takeCount(editor)),
        mapping.ESC => reset(editor),
        mapping.SPACE => {
            editor.leader = true;
            editor.pending = null;
            editor.lastState = .Leader;
        },
        mapping.SCROLL_UP => moveUp(editor, canvas, 1),
        mapping.SCROLL_DOWN => moveDown(editor, canvas, 1),
        else => {},
    }
}
