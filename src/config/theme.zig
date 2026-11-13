const lexer = @import("../lexer/lexer.zig");

pub const reset = "\x1b[0m";

pub const Color = struct {
    fg: []const u8 = "",
    bg: []const u8 = "",
    underline: []const u8 = "",
};

pub const Theme = struct {
    background: []const u8 = "\x1b[48;2;10;14;20m",
    statusLine: []const u8 = "\x1b[48;2;26;32;42m",
    preline: Color = .{ .fg = "\x1b[38;2;53;90;102m", .bg = "" },
    line: Color = .{ .fg = "\x1b[38;2;230;240;255m", .bg = "" },
    stateBlock: Color = .{ .fg = "\x1b[38;2;10;14;20m", .bg = "\x1b[48;2;84;228;247m" },
    cursorLeader: []const u8 = "#64B5F6",
    cursorNormal: []const u8 = "\x1b[38;2;129;212;250m",
    selection: Color = .{ .bg = "\x1b[48;2;33;52;72m" },

    picker: Color = .{ .fg = "\x1b[38;2;230;240;255m", .bg = "\x1b[48;2;16;22;30m" },
    pickerBorder: Color = .{ .fg = "\x1b[38;2;53;90;102m", .bg = "\x1b[48;2;16;22;30m" },
    pickerSelected: Color = .{ .fg = "\x1b[38;2;10;14;20m", .bg = "\x1b[48;2;84;228;247m" },
    pickerHint: Color = .{ .fg = "\x1b[38;2;53;90;102m", .bg = "\x1b[48;2;16;22;30m" },

    tree: Color = .{ .fg = "\x1b[38;2;230;240;255m", .bg = "\x1b[48;2;16;22;30m" },
    treeDir: Color = .{ .fg = "\x1b[38;2;84;228;247m" },
    treeActive: Color = .{ .fg = "\x1b[38;2;84;228;247m", .underline = "\x1b[4m\x1b[58;2;84;228;247m" },
    treeBorder: Color = .{ .fg = "\x1b[38;2;53;90;102m" },
    treeArrow: Color = .{ .fg = "\x1b[38;2;62;110;130m" },
    treeGuide: Color = .{ .fg = "\x1b[38;2;53;90;102m" },

    keyword: Color = .{ .fg = "\x1b[38;2;100;181;246m" },
    string: Color = .{ .fg = "\x1b[38;2;77;208;225m" },
    number: Color = .{ .fg = "\x1b[38;2;129;212;250m" },
    comment: Color = .{ .fg = "\x1b[38;2;53;90;102m" },
    operator: Color = .{ .fg = "\x1b[38;2;230;240;255m" },
};

pub const theme: Theme = .{};

pub fn colorFor(kind: lexer.TokenKind) []const u8 {
    return switch (kind) {
        .keyword => theme.keyword.fg,
        .identifier => theme.line.fg,
        .string => theme.string.fg,
        .number => theme.number.fg,
        .comment => theme.comment.fg,
        .operator => theme.operator.fg,
        .whitespace => theme.line.fg,
    };
}
