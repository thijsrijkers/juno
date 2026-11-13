const std = @import("std");
const Io = std.Io;

const juno = @import("juno");

fn render(
    stdout: *std.Io.Writer,
    editor: *juno.editor.Editor,
    content: *juno.canvas.CanvasContent,
) !void {
    try stdout.writeAll("\x1b[?25l\x1b[?2026h");
    try juno.canvas.draw(stdout, editor, content);
    try stdout.writeAll("\x1b[?2026l");
    try stdout.flush();
}

pub fn main(init: std.process.Init) !void {
    // Argument retrieval
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const allocator = init.gpa;

    var path: ?[]const u8 = if (args.len > 1) args[1] else null;

    // Init editor and system writer/reader
    const io = init.io;
    if (path) |p| {
        if (std.Io.Dir.cwd().openDir(io, p, .{})) |dir| {
            defer dir.close(io);
            try std.process.setCurrentDir(io, dir);
            path = null;
        } else |_| {}
    }

    var editor = juno.editor.init(io);
    try juno.fileTree.open(&editor.tree, io);

    var stdin_buffer: [1]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);

    var stdout_buf: [64 * 1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buf);
    const stdout = &stdout_writer.interface;
    
    // Init canvas and needed info for it
    const terminalSize = try juno.modelSize.getTerminalSize(io);
    var content = juno.canvas.CanvasContent{ 
        .path = path,
        .lines = &.{},
        .loadFromPath = true,
        .canvasSize = terminalSize,
        .previousPaths = .empty,
        .previousContentState = .empty,
    };
    try juno.canvas.compose(io, allocator, &content, &editor);

    const original_term = try juno.modelState.enableRawMode();
    defer juno.modelState.disableRawMode(original_term);

    try juno.modelState.enableMouseReporting(stdout);
    defer juno.modelState.disableMouseReporting(stdout);

    // Key reader blocks event loop, doing one pre render before hand
    try render(stdout, &editor, &content);

    // Event loop
    const stdin_fd = std.Io.File.stdin().handle;
    while (editor.running) {
        const key = try juno.input.readKey(&stdin_reader.interface, stdin_fd);
        try juno.editor.handleKey(&editor, allocator, key, &content);
        try render(stdout, &editor, &content);
    }

    // Cleanup draw
    editor.leader = false;
    try render(stdout, &editor, &content);

    // Clean screen when exitting program
    std.debug.print("\x1b[2J\x1b[H", .{});
}
