const std = @import("std");
const fileWalk = @import("fileWalk.zig");
const mapping = @import("../editor/keyMapping.zig");
const canvasContent = @import("../canvas/canvas.zig");
const Editor = @import("../editor/editor.zig").Editor;
const pickerCanvas = @import("../canvas/picker.zig");

pub const title = " Content ";

const maxLines = 200_000;
const maxMatches = 2000;

pub const Line = struct {
    path: []const u8,
    number: usize,
    text: []const u8,
};

pub const Match = struct {
    line: Line,
    score: i32,
};

pub const Picker = struct {
    active: bool = false,
    query: std.ArrayList(u8) = .empty,
    lines: []const Line = &.{},
    matches: std.ArrayList(Match) = .empty,
    selected: usize = 0,
    scroll: usize = 0,
    arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator),

    pub fn total(picker: *const Picker) usize {
        return picker.lines.len;
    }

    pub fn hint(picker: *const Picker) []const u8 {
        if (picker.query.items.len == 0) return "No matches"; // This message is open to change
        return "No matches";
    }

    pub fn row(picker: *const Picker, index: usize, buffer: []u8) pickerCanvas.Row {
        const line = picker.matches.items[index].line;
        return .{
            .prefix = std.fmt.bufPrint(buffer, "{s}:{d}: ", .{ line.path, line.number }) catch "",
            .text = std.mem.trim(u8, line.text, " \t"),
        };
    }
};

fn collectFile(
    io: std.Io,
    allocator: std.mem.Allocator,
    lines: *std.ArrayList(Line),
    entry: std.Io.Dir.Walker.Entry,
) !void {
    const contents = entry.dir.readFileAlloc(io, entry.basename, allocator, .limited(fileWalk.maxFileSize)) catch return;
    if (std.mem.indexOfScalar(u8, contents, 0) != null) return;

    const path = try allocator.dupe(u8, entry.path);
    var it = std.mem.splitScalar(u8, contents, '\n');
    var number: usize = 1;

    while (it.next()) |text| : (number += 1) {
        if (lines.items.len >= maxLines) return;
        if (text.len == 0) continue;
        try lines.append(allocator, .{ .path = path, .number = number, .text = text });
    }
}

fn collect(io: std.Io, allocator: std.mem.Allocator) ![]const Line {
    var walk = try fileWalk.open(io, allocator);
    defer walk.deinit(io);

    var lines: std.ArrayList(Line) = .empty;
    while (try walk.next(io)) |entry| {
        if (lines.items.len >= maxLines) break;
        try collectFile(io, allocator, &lines, entry);
    }

    return lines.toOwnedSlice(allocator);
}

pub fn score(text: []const u8, query: []const u8) ?i32 {
    const index = std.ascii.findIgnoreCase(text, query) orelse return null;
    return -@as(i32, @intCast(index));
}

fn betterFirst(_: void, a: Match, b: Match) bool {
    return a.score > b.score;
}

fn refresh(picker: *Picker) !void {
    const allocator = picker.arena.allocator();
    const query = picker.query.items;

    picker.matches.clearRetainingCapacity();
    picker.selected = 0;
    picker.scroll = 0;

    if (query.len == 0) return;

    for (picker.lines) |line| {
        if (picker.matches.items.len >= maxMatches) break;
        const value = score(line.text, query) orelse continue;
        try picker.matches.append(allocator, .{ .line = line, .score = value });
    }

    std.mem.sort(Match, picker.matches.items, {}, betterFirst);
}

pub fn open(picker: *Picker, io: std.Io) !void {
    _ = picker.arena.reset(.retain_capacity);

    picker.* = .{ .active = true, .arena = picker.arena };
    picker.lines = try collect(io, picker.arena.allocator());

    try refresh(picker);
}

pub fn close(picker: *Picker) void {
    picker.active = false;
}

fn moveUp(picker: *Picker) void {
    picker.selected -|= 1;
}

fn moveDown(picker: *Picker) void {
    if (picker.matches.items.len == 0) return;
    picker.selected = @min(picker.selected + 1, picker.matches.items.len - 1);
}

fn accept(
    picker: *Picker,
    editor: *Editor,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    if (picker.selected >= picker.matches.items.len) return;
    const line = picker.matches.items[picker.selected].line;

    const alreadyOpen = canvas.path != null and std.mem.eql(u8, canvas.path.?, line.path);
    if (!alreadyOpen) {
        try canvasContent.setPath(canvas, line.path);
        try canvasContent.compose(editor.io, allocator, canvas, editor);
    }

    editor.y = @min(line.number -| 1, canvas.lines.len -| 1);
    editor.x = 0;
    close(picker);
    editor.lastState = .Normal;
}

pub fn handleKey(
    picker: *Picker,
    editor: *Editor,
    allocator: std.mem.Allocator,
    key: u8,
    canvas: *canvasContent.CanvasContent,
) !void {
    switch (key) {
        mapping.ESC => {
            close(picker);
            editor.lastState = .Normal;
        },
        mapping.ENTER, mapping.NEWLINE => try accept(picker, editor, allocator, canvas),
        mapping.ARROW_UP, mapping.SCROLL_UP => moveUp(picker),
        mapping.ARROW_DOWN, mapping.SCROLL_DOWN => moveDown(picker),
        mapping.BACKSPACE => {
            if (picker.query.items.len == 0) return;
            _ = picker.query.pop();
            try refresh(picker);
        },
        else => {
            if (!std.ascii.isPrint(key)) return;
            try picker.query.append(picker.arena.allocator(), key);
            try refresh(picker);
        },
    }
}
