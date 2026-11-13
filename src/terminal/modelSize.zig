const std = @import("std");
const builtin = @import("builtin");

const windows = std.os.windows;

pub const TerminalSize = struct {
    rows: usize,
    cols: usize,
};

/// Returns the terminal's current size, i.e. how many rows/lines the canvas
/// can draw on the y axis and how many columns it can draw on the x axis.
pub fn getTerminalSize(io: std.Io) !TerminalSize {
    const file = std.Io.File.stdout();
    switch (builtin.os.tag) {
        .windows => {
            var get_console_info = windows.CONSOLE.USER_IO.GET_SCREEN_BUFFER_INFO;
            return switch (try get_console_info.operate(io, file)) {
                .SUCCESS => .{
                    .rows = @intCast(get_console_info.Data.dwWindowSize.Y),
                    .cols = @intCast(get_console_info.Data.dwWindowSize.X),
                },
                else => error.Unexpected,
            };
        },
        else => {
            var size: std.posix.winsize = .{ .row = 0, .col = 0, .xpixel = 0, .ypixel = 0 };
            const rc = std.posix.system.ioctl(file.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&size));
            if (std.posix.errno(rc) != .SUCCESS) return error.Unexpected;
            return .{ .rows = size.row, .cols = size.col };
        },
    }
}
