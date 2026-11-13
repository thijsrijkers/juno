const std = @import("std");
const fileTree = @import("../file/fileTree.zig");
const theme = @import("../config/theme.zig");

pub fn drawRow(
    stdout: *std.Io.Writer,
    tree: *const fileTree.Tree,
    screenRow: usize,
    openPath: ?[]const u8,
) !void {
    if (!tree.visible) return;

    try stdout.writeAll(theme.theme.tree.bg);
    var remaining: usize = fileTree.width - 1;

    if (screenRow < tree.nodes.items.len) {
        const node = tree.nodes.items[screenRow];
        const active = !node.isDir and openPath != null and std.mem.eql(u8, openPath.?, node.path);

        try stdout.writeAll(" ");
        remaining -= 1;

        try stdout.writeAll(theme.theme.treeGuide.fg);
        for (0..node.depth) |_| {
            if (remaining < 2) break;
            try stdout.writeAll("│ ");
            remaining -= 2;
        }

        if (node.isDir) {
            try stdout.writeAll(theme.theme.treeDir.fg);
        } else {
            try stdout.writeAll(theme.theme.tree.fg);
        }

        if (remaining >= 2) {
            if (node.isDir) {
                try stdout.writeAll(theme.theme.treeArrow.fg);
                try stdout.writeAll(if (node.expanded) "▼ " else "▶ ");
                try stdout.writeAll(theme.theme.treeDir.fg);
            } else {
                try stdout.writeAll("  ");
            }
            remaining -= 2;
        }

        if (active) {
            try stdout.writeAll(theme.theme.treeActive.fg);
            try stdout.writeAll(theme.theme.treeActive.underline);
        }

        const name = node.name[0..@min(node.name.len, remaining)];
        try stdout.writeAll(name);
        remaining -= name.len;

        try stdout.writeAll(theme.reset);
        try stdout.writeAll(theme.theme.tree.bg);
    }

    try stdout.splatByteAll(' ', remaining);
    try stdout.writeAll(theme.theme.treeBorder.fg);
    try stdout.writeAll("│");
    try stdout.writeAll(theme.reset);
}
