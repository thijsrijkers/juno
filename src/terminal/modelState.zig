//! Raw-mode terminal handling: puts stdin into a mode where keys are
//! delivered to the program as soon as they're pressed, instead of being
//! buffered by the OS until Enter is hit.
const std = @import("std");
const builtin = @import("builtin");

const windows = std.os.windows;

extern "kernel32" fn GetConsoleMode(handle: windows.HANDLE, mode: *windows.DWORD) callconv(.winapi) windows.BOOL;
extern "kernel32" fn SetConsoleMode(handle: windows.HANDLE, mode: windows.DWORD) callconv(.winapi) windows.BOOL;

const ENABLE_PROCESSED_INPUT: windows.DWORD = 0x0001;
const ENABLE_LINE_INPUT: windows.DWORD = 0x0002;
const ENABLE_ECHO_INPUT: windows.DWORD = 0x0004;

pub const RawModeState = switch (builtin.os.tag) {
    .windows => windows.DWORD,
    else => std.posix.termios,
};

/// Puts stdin into raw mode so keys are delivered as soon as they're
/// pressed, instead of being buffered by the terminal until Enter.
pub fn enableRawMode() !RawModeState {
    const handle = std.Io.File.stdin().handle;
    switch (builtin.os.tag) {
        .windows => {
            var mode: windows.DWORD = undefined;
            if (!GetConsoleMode(handle, &mode).toBool()) return error.Unexpected;
            if (!SetConsoleMode(handle, mode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT)).toBool()) return error.Unexpected;
            return mode;
        },
        else => {
            const posix = std.posix;
            const original = try posix.tcgetattr(handle);
            var raw = original;
            raw.lflag.ICANON = false;
            raw.lflag.ECHO = false;
            raw.lflag.ISIG = false; // Ctrl+C/Ctrl+\/Ctrl+Z become plain bytes, not signals
            raw.lflag.IEXTEN = false;
            raw.cc[@intFromEnum(posix.V.MIN)] = 1;
            raw.cc[@intFromEnum(posix.V.TIME)] = 0;
            try posix.tcsetattr(handle, .NOW, raw);
            return original;
        },
    }
}

pub fn disableRawMode(state: RawModeState) void {
    const handle = std.Io.File.stdin().handle;
    switch (builtin.os.tag) {
        .windows => _ = SetConsoleMode(handle, state),
        else => std.posix.tcsetattr(handle, .NOW, state) catch {},
    }
}

/// Asks the terminal to report mouse events (incl. the scroll wheel) as
/// SGR escape sequences on stdin.
pub fn enableMouseReporting(stdout: *std.Io.Writer) !void {
    try stdout.writeAll("\x1b[?1002h\x1b[?1006h");
    try stdout.flush();
}

pub fn disableMouseReporting(stdout: *std.Io.Writer) void {
    stdout.writeAll("\x1b[?1002l\x1b[?1006l") catch {};
    stdout.flush() catch {};
}
