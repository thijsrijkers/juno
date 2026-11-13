const std = @import("std");

pub fn write(io: std.Io, text: []const u8) !void {
    var child = try std.process.spawn(io, .{
        .argv = &.{"pbcopy"},
        .stdin = .pipe,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    try child.stdin.?.writeStreamingAll(io, text);
    child.stdin.?.close(io);
    child.stdin = null;
    _ = try child.wait(io);
}

pub fn read(allocator: std.mem.Allocator, io: std.Io, out: *std.ArrayList(u8)) !void {
    const result = try std.process.run(allocator, io, .{ .argv = &.{"pbpaste"} });
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);
    out.clearRetainingCapacity();
    try out.appendSlice(allocator, result.stdout);
}
