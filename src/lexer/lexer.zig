const std = @import("std");
const keywords = @import("keywords.zig");

pub const TokenKind = enum {
    keyword,
    identifier,
    string,
    number,
    comment,
    operator,
    whitespace,
};

pub const Token = struct {
    text: []const u8,
    kind: TokenKind,
};

pub fn tokenizeLine(allocator: std.mem.Allocator, line: []const u8) ![]Token {
    var tokens: std.ArrayList(Token) = .empty;
    var index: usize = 0;

    while (index < line.len) {
        const character = line[index];

        if (character == ' ' or character == '\t') {
            const start = index;
            while (index < line.len and (line[index] == ' ' or line[index] == '\t')) index += 1;
            try tokens.append(allocator, .{ .text = line[start..index], .kind = .whitespace });
            continue;
        }

        if (character == '/' and index + 1 < line.len and line[index + 1] == '/') {
            try tokens.append(allocator, .{ .text = line[index..], .kind = .comment });
            break;
        }

        if (character == '"') {
            const start = index;
            index += 1;
            while (index < line.len and line[index] != '"') : (index += 1) {
                if (line[index] == '\\') index += 1;
            }
            if (index < line.len) index += 1;
            try tokens.append(allocator, .{ .text = line[start..index], .kind = .string });
            continue;
        }

        if (std.ascii.isDigit(character)) {
            const start = index;
            while (index < line.len and (std.ascii.isAlphanumeric(line[index]) or line[index] == '_' or line[index] == '.')) index += 1;
            try tokens.append(allocator, .{ .text = line[start..index], .kind = .number });
            continue;
        }

        if (std.ascii.isAlphabetic(character) or character == '_') {
            const start = index;
            while (index < line.len and (std.ascii.isAlphanumeric(line[index]) or line[index] == '_')) index += 1;
            const word = line[start..index];
            try tokens.append(allocator, .{ .text = word, .kind = if (keywords.isKeyword(word)) .keyword else .identifier });
            continue;
        }

        try tokens.append(allocator, .{ .text = line[index .. index + 1], .kind = .operator });
        index += 1;
    }

    return tokens.toOwnedSlice(allocator);
}
