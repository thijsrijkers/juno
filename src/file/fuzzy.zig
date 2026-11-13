const std = @import("std");

fn isBoundary(character: u8) bool {
    return switch (character) {
        '/', '_', '-', '.', ' ' => true,
        else => false,
    };
}

fn scoreRun(text: []const u8, query: []const u8, basename: usize) ?i32 {
    var total: i32 = 0;
    var streak: i32 = 0;
    var matched: usize = 0;

    for (text, 0..) |character, index| {
        if (matched == query.len) break;
        if (std.ascii.toLower(character) != std.ascii.toLower(query[matched])) {
            streak = 0;
            continue;
        }

        streak += 1;
        total += 1 + streak * 4;
        if (index >= basename) total += 8;
        if (index == 0 or isBoundary(text[index - 1])) total += 6;
        matched += 1;
    }

    if (matched != query.len) return null;
    return total;
}

pub fn score(text: []const u8, query: []const u8) ?i32 {
    if (query.len == 0) return 0;

    const basename = if (std.mem.lastIndexOfScalar(u8, text, '/')) |index| index + 1 else 0;
    const whole = scoreRun(text, query, basename);
    const best = if (basename == 0) whole else blk: {
        const partial = scoreRun(text[basename..], query, 0) orelse break :blk whole;
        break :blk @max(partial, whole orelse partial);
    };

    return (best orelse return null) - @as(i32, @intCast(text.len / 4));
}
