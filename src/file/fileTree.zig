const std = @import("std");
const fileWalk = @import("fileWalk.zig");
const canvasContent = @import("../canvas/canvas.zig");
const Editor = @import("../editor/editor.zig").Editor;

pub const width = 28;

pub const Node = struct {
    name: []const u8,
    path: []const u8,
    depth: usize,
    isDir: bool,
    expanded: bool = false,
};

pub const Tree = struct {
    visible: bool = false,
    loaded: bool = false,
    nodes: std.ArrayList(Node) = .empty,
    arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator),
};

fn dirsFirst(_: void, a: Node, b: Node) bool {
    if (a.isDir != b.isDir) return a.isDir;
    return std.mem.lessThan(u8, a.name, b.name);
}

fn readDir(io: std.Io, allocator: std.mem.Allocator, path: []const u8, depth: usize) ![]Node {
    var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var nodes: std.ArrayList(Node) = .empty;
    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (fileWalk.skip(entry.name)) continue;
        const isDir = switch (entry.kind) {
            .directory => true,
            .file => false,
            else => continue,
        };

        const name = try allocator.dupe(u8, entry.name);
        const childPath = if (depth == 0) name else try std.fs.path.join(allocator, &.{ path, name });
        try nodes.append(allocator, .{ .name = name, .path = childPath, .depth = depth, .isDir = isDir });
    }

    std.mem.sort(Node, nodes.items, {}, dirsFirst);
    return nodes.toOwnedSlice(allocator);
}

pub fn open(tree: *Tree, io: std.Io) !void {
    if (!tree.loaded) {
        const allocator = tree.arena.allocator();
        try tree.nodes.appendSlice(allocator, try readDir(io, allocator, ".", 0));
        tree.loaded = true;
    }
    tree.visible = true;
}

pub fn toggle(tree: *Tree, io: std.Io) !void {
    if (tree.visible) tree.visible = false else try open(tree, io);
}

pub fn offset(tree: *const Tree) usize {
    return if (tree.visible) width else 0;
}

fn expand(tree: *Tree, io: std.Io, index: usize) !void {
    const allocator = tree.arena.allocator();
    const node = tree.nodes.items[index];
    const children = try readDir(io, allocator, node.path, node.depth + 1);

    tree.nodes.items[index].expanded = true;
    try tree.nodes.insertSlice(allocator, index + 1, children);
}

fn collapse(tree: *Tree, index: usize) void {
    const depth = tree.nodes.items[index].depth;
    var end = index + 1;
    while (end < tree.nodes.items.len and tree.nodes.items[end].depth > depth) end += 1;

    tree.nodes.replaceRangeAssumeCapacity(index + 1, end - (index + 1), &.{});
    tree.nodes.items[index].expanded = false;
}

pub fn handleClick(
    tree: *Tree,
    editor: *Editor,
    allocator: std.mem.Allocator,
    row: usize,
    canvas: *canvasContent.CanvasContent,
) !void {
    const index = row -| (canvasContent.topBar + 1);
    if (index >= tree.nodes.items.len) return;
    const node = tree.nodes.items[index];

    if (node.isDir) {
        if (node.expanded) collapse(tree, index) else try expand(tree, editor.io, index);
        return;
    }

    const alreadyOpen = canvas.path != null and std.mem.eql(u8, canvas.path.?, node.path);
    if (!alreadyOpen) {
        try canvasContent.setPath(canvas, node.path);
        try canvasContent.compose(editor.io, allocator, canvas, editor);
    }
}
