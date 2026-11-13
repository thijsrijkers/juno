const std = @import("std");
const fileWalk = @import("fileWalk.zig");
const fuzzy = @import("fuzzy.zig");
const mapping = @import("../editor/keyMapping.zig");
const canvasContent = @import("../canvas/canvas.zig");
const Editor = @import("../editor/editor.zig").Editor;
const pickerCanvas = @import("../canvas/picker.zig");

pub const title = " Files ";

const maxFiles = 20_000;

pub const Match = struct {
    path: []const u8,
    score: i32,
};

pub const Picker = struct {
    active: bool = false,
    query: std.ArrayList(u8) = .empty,
    paths: []const []const u8 = &.{},
    matches: std.ArrayList(Match) = .empty,
    selected: usize = 0,
    scroll: usize = 0,
    arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator),

    pub fn total(picker: *const Picker) usize {
        return picker.paths.len;
    }

    pub fn hint(_: *const Picker) []const u8 {
        return "No matches";
    }

    pub fn row(picker: *const Picker, index: usize, _: []u8) pickerCanvas.Row {
        return .{ .text = picker.matches.items[index].path, .clipFront = true };
    }
};

fn collect(io: std.Io, allocator: std.mem.Allocator) ![]const []const u8 {
    var walk = try fileWalk.open(io, allocator);
    defer walk.deinit(io);

    var paths: std.ArrayList([]const u8) = .empty;
    while (try walk.next(io)) |entry| {
        if (paths.items.len >= maxFiles) break;
        try paths.append(allocator, try allocator.dupe(u8, entry.path));
    }

    return paths.toOwnedSlice(allocator);
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

    for (picker.paths) |path| {
        const value = fuzzy.score(path, query) orelse continue;
        try picker.matches.append(allocator, .{ .path = path, .score = value });
    }

    if (query.len > 0) std.mem.sort(Match, picker.matches.items, {}, betterFirst);
}

pub fn open(picker: *Picker, io: std.Io) !void {
    _ = picker.arena.reset(.retain_capacity);

    picker.* = .{ .active = true, .arena = picker.arena };
    picker.paths = try collect(io, picker.arena.allocator());

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
    const path = picker.matches.items[picker.selected].path;

    const alreadyOpen = canvas.path != null and std.mem.eql(u8, canvas.path.?, path);
    if (!alreadyOpen) {
        try canvasContent.setPath(canvas, path);
        try canvasContent.compose(editor.io, allocator, canvas, editor);
    }

    editor.x = 0;
    editor.y = 0;
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
