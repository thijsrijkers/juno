const std = @import("std");

const ignoredDirs = [_][]const u8{ "node_modules", "zig-out", "target", "vendor" };

pub const maxFileSize = 1 << 20;

pub fn skip(name: []const u8) bool {
    if (name.len > 0 and name[0] == '.') return true;
    for (ignoredDirs) |dir| if (std.mem.eql(u8, name, dir)) return true;
    return false;
}

pub const Walk = struct {
    root: std.Io.Dir,
    walker: std.Io.Dir.SelectiveWalker,

    pub fn next(self: *Walk, io: std.Io) !?std.Io.Dir.Walker.Entry {
        while (true) {
            const result = self.walker.next(io) catch continue;
            const entry = result orelse return null;
            if (skip(entry.basename)) continue;

            switch (entry.kind) {
                .directory => self.walker.enter(io, entry) catch |err| switch (err) {
                    error.OutOfMemory => return err,
                    else => {},
                },
                .file => return entry,
                else => {},
            }
        }
    }

    pub fn deinit(self: *Walk, io: std.Io) void {
        while (self.walker.stack.items.len > 0) self.walker.leave(io);
        self.walker.deinit();
        self.root.close(io);
    }
};

pub fn open(io: std.Io, allocator: std.mem.Allocator) !Walk {
    var root = try std.Io.Dir.cwd().openDir(io, ".", .{ .iterate = true });
    errdefer root.close(io);

    return .{ .root = root, .walker = try root.walkSelectively(allocator) };
}
