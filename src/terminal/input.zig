const std = @import("std");
const mapping = @import("../editor/keyMapping.zig");

fn hasPendingInput(fd: std.posix.fd_t) bool {
    var fds = [1]std.posix.pollfd{.{ .fd = fd, .events = std.posix.POLL.IN, .revents = 0 }};
    const n = std.posix.poll(&fds, 0) catch return false;
    return n > 0;
}

pub fn readKey(reader: *std.Io.Reader, fd: std.posix.fd_t) !mapping.KeyEvent {
    const key = try reader.takeByte();
    if (key != mapping.ESC or !hasPendingInput(fd)) return .{ .key = key };

    if ((try reader.takeByte()) != '[') return .{ .key = key };

    switch (try reader.takeByte()) {
        'A' => return .{ .key = mapping.ARROW_UP },
        'B' => return .{ .key = mapping.ARROW_DOWN },
        'C' => return .{ .key = mapping.ARROW_RIGHT },
        'D' => return .{ .key = mapping.ARROW_LEFT },
        '<' => {},
        else => return .{ .key = key },
    }

    var fields = [3]usize{ 0, 0, 0 };
    var field: usize = 0;
    const final = while (true) {
        const c = try reader.takeByte();
        switch (c) {
            '0'...'9' => fields[field] = fields[field] * 10 + (c - '0'),
            ';' => field = @min(field + 1, fields.len - 1),
            else => break c,
        }
    };

    const button = fields[0];
    return switch (button) {
        64 => .{ .key = mapping.SCROLL_UP },
        65 => .{ .key = mapping.SCROLL_DOWN },
        0 => .{
            .key = if (final == 'M') mapping.MOUSE_CLICK else mapping.MOUSE_RELEASE,
            .col = fields[1],
            .row = fields[2],
        },
        32 => .{ .key = mapping.MOUSE_DRAG, .col = fields[1], .row = fields[2] },
        else => .{ .key = mapping.NONE },
    };
}
