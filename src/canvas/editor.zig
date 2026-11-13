const std = @import("std");
const Editor = @import("../editor/editor.zig").Editor;
const fileContent = @import("../file/fileContent.zig");
const theme = @import("../config/theme.zig");
const canvas = @import("./canvas.zig");
const lexer = @import("../lexer/lexer.zig");
const fileTree = @import("../file/fileTree.zig");
const selection = @import("../editor/selection.zig");

pub fn drawLine(
    stdout: *std.Io.Writer,
    allocator: std.mem.Allocator,
    content: *const canvas.CanvasContent,
    lineIdx: usize,
    left: usize,
    sel: ?selection.Selection,
) !void {
    const row = content.grid.rows[lineIdx];
    const digits = std.fmt.count("{d}", .{row.number});
    try stdout.writeAll(theme.theme.preline.bg);
    try stdout.writeAll(theme.theme.preline.fg);
    try stdout.splatByteAll(' ', content.grid.numberWidth - digits);
    try stdout.print("{d}   ", .{ row.number });
    try stdout.writeAll(theme.reset);
    try stdout.writeAll(theme.theme.background);
    try stdout.writeAll(theme.theme.line.bg);

    const line = content.lines[lineIdx].items;
    const range = if (sel) |s| selection.columnsOnLine(s, lineIdx, line.len) else null;

    var remaining = content.canvasSize.cols -| (left + content.grid.numberWidth + 3);
    var col: usize = 0;
    const tokens = try lexer.tokenizeLine(allocator, line);
    for (tokens) |token| {
        if (remaining == 0) break;
        const text = token.text[0..@min(token.text.len, remaining)];
        remaining -= text.len;
        try stdout.writeAll(theme.colorFor(token.kind));
        try writeWithSelection(stdout, text, col, range);
        col += text.len;
    }
}

fn writeWithSelection(stdout: *std.Io.Writer, text: []const u8, col: usize, range: ?struct { usize, usize }) !void {
    const from, const to = range orelse return stdout.writeAll(text);
    const a = std.math.clamp(from, col, col + text.len) - col;
    const b = std.math.clamp(to, col, col + text.len) - col;
    if (a == b) return stdout.writeAll(text);

    try stdout.writeAll(text[0..a]);
    try stdout.writeAll(theme.theme.selection.bg);
    try stdout.writeAll(text[a..b]);
    try stdout.writeAll(theme.theme.background);
    try stdout.writeAll(text[b..]);
}

pub fn drawEditorState(stdout: *std.Io.Writer, editor: *const Editor, content: *const canvas.CanvasContent) !void {
    try stdout.writeAll(theme.theme.statusLine);
    try stdout.writeAll(theme.theme.line.fg);

    if (editor.leader or editor.insert) {
        try stdout.writeAll(theme.theme.stateBlock.bg);
        try stdout.writeAll(theme.theme.stateBlock.fg);
    } else {
        try stdout.writeAll(theme.theme.number.fg);
    }

    switch (editor.lastState) {
        .Normal => try stdout.writeAll(" NORMAL "),
        .Editing => try stdout.writeAll(" INSERT "),
        .Saved => try stdout.writeAll(" SAVED "),
        .Leader => try stdout.writeAll(" LEADER "),
        .Search => try stdout.writeAll(" SEARCH "),
    }
    try stdout.writeAll(theme.reset);
    try stdout.writeAll(theme.theme.statusLine);

    if (content.path) |path| {
        try stdout.writeAll(" ");
        try stdout.writeAll(path);
    }

    if (editor.pending) |pending| {
        try stdout.writeAll(theme.theme.comment.fg);
        try stdout.print(" | {d}", .{pending});
    }

    try stdout.writeAll("\x1b[K");
}

pub fn drawCursor(stdout: *std.Io.Writer, editor: *const Editor, content: *const canvas.CanvasContent) !void {
    const maxRow = if (content.grid.rows.len == 0) 0 else content.grid.rows.len - 1;
    const cursorRow = @min(editor.y, maxRow);
    const gutterWidth = content.grid.numberWidth + 3; // "N | "
    const lineLen = if (content.lines.len == 0) 0 else content.lines[cursorRow].items.len;
    const cursorCol = @min(editor.x, lineLen);

    if (editor.leader) {
        try setCursorColor(stdout, theme.theme.cursorLeader);
    } else {
        try setCursorColor(stdout, theme.theme.cursorNormal);
    }

    try stdout.print("\x1b[{d};{d}H", .{ canvas.topBar + cursorRow - content.scrollOffset + 1, fileTree.offset(&editor.tree) + gutterWidth + cursorCol + 1 });
}

fn setCursorColor(stdout: *std.Io.Writer, hex: []const u8) !void {
    try stdout.print("\x1b]12;{s}\x1b\\", .{hex});
}
