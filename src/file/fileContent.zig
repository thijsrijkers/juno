const std = @import("std");
const canvasContent = @import("../canvas/canvas.zig");
const Editor = @import("../editor/editor.zig").Editor;

pub fn getFileContent(io: std.Io, allocator: std.mem.Allocator, path: []const u8) ![]std.ArrayList(u8) {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .unlimited);
    defer allocator.free(contents);

    var lines: std.ArrayList(std.ArrayList(u8)) = .empty;
    errdefer {
        for (lines.items) |*line| line.deinit(allocator);
        lines.deinit(allocator);
    }

    var it = std.mem.splitScalar(u8, contents, '\n');
    while (it.next()) |line| {
        var owned: std.ArrayList(u8) = .empty;
        try owned.appendSlice(allocator, line);
        try lines.append(allocator, owned);
    }

    if (contents.len > 0 and contents[contents.len - 1] == '\n') {
        var last = lines.pop().?;
        last.deinit(allocator);
    }

    return lines.toOwnedSlice(allocator);
}

pub fn writeFileContent(allocator: std.mem.Allocator, editor: *Editor, canvas: *canvasContent.CanvasContent) !bool {
    if (canvas.path) |path| {
        var data: std.ArrayList(u8) = .empty;
        defer data.deinit(allocator);

        for (canvas.lines) |line| {
            try data.appendSlice(allocator, line.items);
            try data.append(allocator, '\n');
        }

        try std.Io.Dir.writeFile(std.Io.Dir.cwd(), editor.io, .{
            .sub_path = path,
            .data = data.items,
        });

        return true;
    }

    return false;
}
