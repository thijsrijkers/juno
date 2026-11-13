const std = @import("std");
const canvasContent = @import("./canvas.zig");

pub fn pushPreviousState(
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    const snapshot = try allocator.alloc(std.ArrayList(u8), canvas.lines.len);
    for (canvas.lines, 0..) |line, i| {
        snapshot[i] = .empty;
        try snapshot[i].appendSlice(allocator, line.items);
    }
    try canvas.previousContentState.append(allocator, snapshot);
}

pub fn undo(
    allocator: std.mem.Allocator,
    canvas: *canvasContent.CanvasContent,
) !void {
    const snapshot = canvas.previousContentState.pop() orelse return;

    for (canvas.lines) |*line| line.deinit(allocator);
    allocator.free(canvas.lines);
    canvas.lines = snapshot;

    allocator.free(canvas.grid.rows);
    canvas.grid = try canvasContent.buildGrid(allocator, canvas.lines);
}
