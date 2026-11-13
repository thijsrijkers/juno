const std = @import("std");
const canvasContent = @import("../canvas/canvas.zig");

pub const Point = struct {
    x: usize,
    y: usize,

    fn before(a: Point, b: Point) bool {
        return a.y < b.y or (a.y == b.y and a.x < b.x);
    }
};

pub const Selection = struct {
    start: Point,
    end: Point,
    active: bool = true,
};

pub fn ordered(sel: Selection) struct { Point, Point } {
    return if (sel.end.before(sel.start)) .{ sel.end, sel.start } else .{ sel.start, sel.end };
}

pub fn isEmpty(sel: Selection) bool {
    return sel.start.x == sel.end.x and sel.start.y == sel.end.y;
}

pub fn columnsOnLine(sel: Selection, lineIdx: usize, lineLen: usize) ?struct { usize, usize } {
    const start, const end = ordered(sel);
    if (lineIdx < start.y or lineIdx > end.y) return null;
    const from = if (lineIdx == start.y) @min(start.x, lineLen) else 0;
    const to = if (lineIdx == end.y) @min(end.x, lineLen) else lineLen;
    return .{ from, to };
}

pub fn copy(
    sel: Selection,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
    out: *std.ArrayList(u8),
) !void {
    out.clearRetainingCapacity();
    const start, const end = ordered(sel);
    for (start.y..end.y + 1) |y| {
        const line = canvas.lines[y].items;
        const from, const to = columnsOnLine(sel, y, line.len).?;
        try out.appendSlice(allocator, line[from..to]);
        if (y != end.y) try out.append(allocator, '\n');
    }
}

pub fn delete(
    sel: Selection,
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !Point {
    const start, const end = ordered(sel);
    const first = &canvas.lines[start.y];
    const startX = @min(start.x, first.items.len);

    if (start.y == end.y) {
        const endX = @min(end.x, first.items.len);
        try first.replaceRange(allocator, startX, endX - startX, &.{});
        return .{ .x = startX, .y = start.y };
    }

    const last = canvas.lines[end.y].items;
    first.shrinkRetainingCapacity(startX);
    try first.appendSlice(allocator, last[@min(end.x, last.len)..]);
    for (canvas.lines[start.y + 1 .. end.y + 1]) |*line| line.deinit(allocator);

    var new_lines = try allocator.alloc(std.ArrayList(u8), canvas.lines.len - (end.y - start.y));
    @memcpy(new_lines[0 .. start.y + 1], canvas.lines[0 .. start.y + 1]);
    @memcpy(new_lines[start.y + 1 ..], canvas.lines[end.y + 1 ..]);
    allocator.free(canvas.lines);
    canvas.lines = new_lines;

    allocator.free(canvas.grid.rows);
    canvas.grid = try canvasContent.buildGrid(allocator, canvas.lines);

    return .{ .x = startX, .y = start.y };
}
