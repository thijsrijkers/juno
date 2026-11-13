//! Rendering pipeline: draws editor state to the terminal.
const std = @import("std");
const Editor = @import("../editor/editor.zig").Editor;
const fileContent = @import("../file/fileContent.zig");
const modelSize = @import("../terminal/modelSize.zig");
const theme = @import("../config/theme.zig");
const pickerCanvas = @import("picker.zig");
const fileSearch = @import("../file/fileSearch.zig");
const contentSearch = @import("../file/contentSearch.zig");
const bufferSearch = @import("../file/bufferSearch.zig");
const editorDraw = @import("./editor.zig");
const treeDraw = @import("./tree.zig");
const fileTree = @import("../file/fileTree.zig");

pub const topBar = 1;

pub const GridRow = struct {
    number: usize,
    divider: u8 = '|',
};

pub const Grid = struct {
    rows: []GridRow,
    numberWidth: usize,
};

pub const CanvasContent = struct {
    path: ?[]const u8,
    lines: []std.ArrayList(u8),
    grid: Grid = .{ .rows = &.{}, .numberWidth = 0 },
    canvasSize: modelSize.TerminalSize,
    scrollOffset: usize = 0,
    loadFromPath: bool = false,
    previousPaths: std.ArrayList([]const u8),
    previousContentState: std.ArrayList([]std.ArrayList(u8)),
};

pub fn setPath(content: *CanvasContent, path: []const u8) !void {
    content.path = path;
    content.loadFromPath = true;
}

pub fn buildGrid(allocator: std.mem.Allocator, lines: []std.ArrayList(u8)) !Grid {
    const rows = try allocator.alloc(GridRow, lines.len);
    for (0..lines.len) |i| {
        rows[i] = .{ .number = i + 1 };
    }
    return .{
        .rows = rows,
        .numberWidth = std.fmt.count("{d}", .{lines.len}),
    };
}

fn internPath(allocator: std.mem.Allocator, content: *CanvasContent, path: []const u8) ![]const u8 {
    for (content.previousPaths.items) |seen| {
        if (std.mem.eql(u8, seen, path)) return seen;
    }
    const owned = try allocator.dupe(u8, path);
    errdefer allocator.free(owned);
    try content.previousPaths.append(allocator, owned);
    return owned;
}

fn freeBuffer(allocator: std.mem.Allocator, content: *CanvasContent) void {
    for (content.lines) |*line| line.deinit(allocator);
    allocator.free(content.lines);
    allocator.free(content.grid.rows);
    content.lines = &.{};
    content.grid = .{ .rows = &.{}, .numberWidth = 0 };
}

pub fn compose(io: std.Io, allocator: std.mem.Allocator, content: *CanvasContent, editor: *Editor) !void {
    if (content.loadFromPath) {
        if (content.path) |requested| {
            if (std.mem.eql(u8, requested, ".")) {
                return;
            }

            const path = try internPath(allocator, content, requested);
            content.path = path;

            const loaded = try fileContent.getFileContent(io, allocator, path);
            freeBuffer(allocator, content);
            content.lines = loaded;

            if (content.lines.len == 0) {
                const lines = try allocator.alloc(std.ArrayList(u8), 1);
                lines[0] = .empty;
                content.lines = lines;
            }

            content.grid = try buildGrid(allocator, content.lines);
            content.loadFromPath = false;

            // Undo history and the viewport belong to the buffer that was open, not to the one replacing it.
            for (content.previousContentState.items) |snapshot| {
                for (snapshot) |*line| line.deinit(allocator);
                allocator.free(snapshot);
            }
            content.previousContentState.clearRetainingCapacity();

            content.scrollOffset = 0;
            editor.x = 0;
            editor.y = 0;
            content.canvasSize = try modelSize.getTerminalSize(io);
        }
    }
}

pub fn draw(stdout: *std.Io.Writer, editor: *Editor, content: *CanvasContent) !void {
    const rows = content.canvasSize.rows -| (topBar + 1);
    const maxRow = if (content.grid.rows.len == 0) 0 else content.grid.rows.len - 1;
    const cursorRow = @min(editor.y, maxRow);

    // Sticky viewport: stays put unless the cursor goes above the top row
    // currently shown, or below the bottom row currently shown.
    if (cursorRow < content.scrollOffset) {
        content.scrollOffset = cursorRow;
    } else if (cursorRow >= content.scrollOffset + rows) {
        content.scrollOffset = cursorRow - rows + 1;
    }

    try stdout.writeAll("\x1b[?25l");

    // Per-frame scratch allocator for token spans; freed once the frame is drawn.
    var lineArena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer lineArena.deinit();
    const tokenAllocator = lineArena.allocator();

    const viewEnd = @min(content.scrollOffset + rows, content.grid.rows.len);
    try stdout.writeAll("\x1b[1;1H");
    try stdout.writeAll(theme.theme.statusLine);
    try stdout.writeAll("\x1b[K");
    try stdout.writeAll(theme.reset);

    for (0..rows) |screenRow| {
        const lineIdx = content.scrollOffset + screenRow;
        try stdout.print("\x1b[{d};1H", .{topBar + screenRow + 1});
        try treeDraw.drawRow(stdout, &editor.tree, screenRow, content.path);
        try stdout.writeAll(theme.theme.background);

        if (lineIdx < viewEnd) try editorDraw.drawLine(stdout, tokenAllocator, content, lineIdx, fileTree.offset(&editor.tree), editor.selection);

        try stdout.writeAll(theme.reset);
        try stdout.writeAll(theme.theme.background);
        try stdout.writeAll("\x1b[K");
    }

    try stdout.print("\x1b[{d};1H", .{content.canvasSize.rows});
    try editorDraw.drawEditorState(stdout, editor, content);

    if (editor.filePicker.active) {
        try pickerCanvas.draw(stdout, &editor.filePicker, fileSearch.title, content.canvasSize);
    } else if (editor.contentPicker.active) {
        try pickerCanvas.draw(stdout, &editor.contentPicker, contentSearch.title, content.canvasSize);
    } else if (editor.bufferPicker.active) {
        try pickerCanvas.draw(stdout, &editor.bufferPicker, bufferSearch.title, content.canvasSize);
    } else {
        try editorDraw.drawCursor(stdout, editor, content);
    }

    try stdout.writeAll("\x1b[?25h");
    try stdout.flush();
}
