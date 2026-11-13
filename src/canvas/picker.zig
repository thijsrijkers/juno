const std = @import("std");
const modelSize = @import("../terminal/modelSize.zig");
const theme = @import("../config/theme.zig");

const chrome = 4;
const maxWidth = 90;
const maxHeight = 20;
const minWidth = 30;
const minHeight = 8;

pub const Row = struct {
    prefix: []const u8 = "",
    text: []const u8,
    clipFront: bool = false,
};

const Box = struct {
    top: usize,
    left: usize,
    width: usize,
    height: usize,

    fn inner(box: Box) usize {
        return box.width - 4;
    }

    fn rows(box: Box) usize {
        return box.height - chrome;
    }
};

fn layout(size: modelSize.TerminalSize) ?Box {
    if (size.cols < minWidth or size.rows < minHeight) return null;

    const width = @min(size.cols -| 8, maxWidth);
    const height = @min(size.rows -| 4, maxHeight);
    return .{
        .top = (size.rows - height) / 2 + 1,
        .left = (size.cols - width) / 2 + 1,
        .width = width,
        .height = height,
    };
}

fn repeat(stdout: *std.Io.Writer, text: []const u8, count: usize) !void {
    for (0..count) |_| try stdout.writeAll(text);
}

fn moveTo(stdout: *std.Io.Writer, row: usize, col: usize) !void {
    try stdout.print("\x1b[{d};{d}H", .{ row, col });
}

fn writeCell(stdout: *std.Io.Writer, text: []const u8, width: usize, clipFront: bool) !void {
    if (width == 0) return;

    if (text.len <= width) {
        try stdout.writeAll(text);
        try stdout.splatByteAll(' ', width - text.len);
        return;
    }

    if (clipFront) {
        try stdout.writeAll("…");
        try stdout.writeAll(text[text.len - (width - 1) ..]);
    } else {
        try stdout.writeAll(text[0 .. width - 1]);
        try stdout.writeAll("…");
    }
}

fn drawTopBorder(stdout: *std.Io.Writer, box: Box, title: []const u8) !void {
    try stdout.writeAll(theme.theme.pickerBorder.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("╭─");
    try stdout.writeAll(theme.theme.picker.fg);
    try stdout.writeAll(title);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try repeat(stdout, "─", box.width -| (3 + title.len));
    try stdout.writeAll("╮");
}

fn drawBottomBorder(stdout: *std.Io.Writer, box: Box, shown: usize, total: usize) !void {
    var counter: [32]u8 = undefined;
    const label = std.fmt.bufPrint(&counter, " {d}/{d} ", .{ shown, total }) catch " ";

    try stdout.writeAll(theme.theme.pickerBorder.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("╰─");
    try stdout.writeAll(label);
    try repeat(stdout, "─", box.width -| (3 + label.len));
    try stdout.writeAll("╯");
}

fn drawQuery(stdout: *std.Io.Writer, box: Box, query: []const u8) !void {
    try stdout.writeAll(theme.theme.picker.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("│ ");
    try stdout.writeAll(theme.theme.pickerSelected.fg);
    try stdout.writeAll("❯ ");
    try stdout.writeAll(theme.theme.picker.fg);
    try writeCell(stdout, query, box.inner() -| 2, false);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll(" │");
}

fn drawSeparator(stdout: *std.Io.Writer, box: Box) !void {
    try stdout.writeAll(theme.theme.pickerBorder.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("├");
    try repeat(stdout, "─", box.width - 2);
    try stdout.writeAll("┤");
}

fn drawRow(stdout: *std.Io.Writer, box: Box, row: Row, selected: bool) !void {
    try stdout.writeAll(theme.theme.picker.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("│ ");

    if (selected) {
        try stdout.writeAll(theme.theme.pickerSelected.bg);
        try stdout.writeAll(theme.theme.pickerSelected.fg);
    } else {
        try stdout.writeAll(theme.theme.picker.fg);
    }

    var remaining = box.inner();
    if (row.prefix.len > 0) {
        const width = @min(row.prefix.len, remaining);
        try writeCell(stdout, row.prefix[0..width], width, false);
        remaining -= width;
    }
    try writeCell(stdout, row.text, remaining, row.clipFront);

    try stdout.writeAll(theme.theme.picker.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll(" │");
}

fn drawHint(stdout: *std.Io.Writer, box: Box, hint: []const u8) !void {
    try stdout.writeAll(theme.theme.picker.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("│ ");
    try stdout.writeAll(theme.theme.pickerHint.fg);
    try writeCell(stdout, hint, box.inner(), false);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll(" │");
}

fn drawFiller(stdout: *std.Io.Writer, box: Box) !void {
    try stdout.writeAll(theme.theme.picker.bg);
    try stdout.writeAll(theme.theme.pickerBorder.fg);
    try stdout.writeAll("│");
    try stdout.splatByteAll(' ', box.width - 2);
    try stdout.writeAll("│");
}

fn follow(selected: usize, scroll: *usize, rows: usize) void {
    if (selected < scroll.*) {
        scroll.* = selected;
    } else if (selected >= scroll.* + rows) {
        scroll.* = selected - rows + 1;
    }
}

pub fn draw(
    stdout: *std.Io.Writer,
    picker: anytype,
    title: []const u8,
    size: modelSize.TerminalSize,
) !void {
    const box = layout(size) orelse return;
    follow(picker.selected, &picker.scroll, box.rows());

    try moveTo(stdout, box.top, box.left);
    try drawTopBorder(stdout, box, title);

    try moveTo(stdout, box.top + 1, box.left);
    try drawQuery(stdout, box, picker.query.items);

    try moveTo(stdout, box.top + 2, box.left);
    try drawSeparator(stdout, box);

    for (0..box.rows()) |row| {
        const index = picker.scroll + row;
        try moveTo(stdout, box.top + 3 + row, box.left);

        if (index < picker.matches.items.len) {
            var buffer: [512]u8 = undefined;
            try drawRow(stdout, box, picker.row(index, &buffer), index == picker.selected);
        } else if (row == 0) {
            try drawHint(stdout, box, picker.hint());
        } else {
            try drawFiller(stdout, box);
        }
    }

    try moveTo(stdout, box.top + box.height - 1, box.left);
    try drawBottomBorder(stdout, box, picker.matches.items.len, picker.total());
    try stdout.writeAll(theme.reset);

    try moveTo(stdout, box.top + 1, box.left + 4 + @min(picker.query.items.len, box.inner() -| 2));
}
