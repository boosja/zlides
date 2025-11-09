const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

fn isWhitespace(c: u8) bool {
    return switch (c) {
        ' ',
        9, // horizontal tab \t
        10, // line feed \n
        11, // vertical tab \v
        12, // form feed \f
        13, // carriage return \r
        => true,
        else => false,
    };
}

test "checks if whitespace" {
    try std.testing.expect(isWhitespace(' '));
    try std.testing.expect(isWhitespace(9));
    try std.testing.expect(isWhitespace(10));
    try std.testing.expect(isWhitespace(11));
    try std.testing.expect(isWhitespace(12));
    try std.testing.expect(isWhitespace(13));
    try std.testing.expect(!isWhitespace('a'));
}

fn isDelimiter(c: u8) bool {
    return switch (c) {
        '(', ')', '[', ']', '{', '}', ',', ':', ';', '*', '!', '?' => true,
        else => false,
    };
}

test "checks if delimiter" {
    try std.testing.expect(isDelimiter('('));
    try std.testing.expect(isDelimiter(')'));
    try std.testing.expect(isDelimiter('['));
    try std.testing.expect(isDelimiter(']'));
    try std.testing.expect(isDelimiter('{'));
    try std.testing.expect(isDelimiter('}'));
    try std.testing.expect(isDelimiter(','));
    try std.testing.expect(!isDelimiter('a'));
}

fn getChar(i: usize, s: []const u8) ?u8 {
    return if (i < s.len) s[i] else null;
}

fn appendIfPopulated(allocator: Allocator, tokens: *ArrayList([]const u8), token: *ArrayList(u8)) !void {
    if (token.items.len > 0) {
        try tokens.append(allocator, try token.toOwnedSlice(allocator));
    }
}

pub fn tokenize(allocator: Allocator, s: []const u8) ![][]const u8 {
    var tokens = try ArrayList([]const u8).initCapacity(allocator, 0);

    var currentToken = try ArrayList(u8).initCapacity(allocator, 0);
    defer currentToken.deinit(allocator);

    var i: usize = 0;
    while (getChar(i, s)) |c| : (i += 1) {
        if (isWhitespace(c) or isDelimiter(c)) {
            try appendIfPopulated(allocator, &tokens, &currentToken);

            var delim = try allocator.alloc(u8, 1);
            delim[0] = c;
            try tokens.append(allocator, delim);
        } else if (c == '"') {
            try currentToken.append(allocator, c);
            i += 1;
            while (getChar(i, s)) |sc| : (i += 1) {
                try currentToken.append(allocator, sc);
                if (sc == '"' and getChar(i - 1, s) != '\\') {
                    try appendIfPopulated(allocator, &tokens, &currentToken);
                    break;
                }
            }
        } else if (c == '/' and getChar(i + 1, s) == '/') {
            try currentToken.append(allocator, c);
            i += 1;
            while (getChar(i, s)) |sc| : (i += 1) {
                try currentToken.append(allocator, sc);
                if (sc == '\n') {
                    try appendIfPopulated(allocator, &tokens, &currentToken);
                    break;
                }
            }
        } else {
            try currentToken.append(allocator, c);
        }
    }

    try appendIfPopulated(allocator, &tokens, &currentToken);

    return tokens.toOwnedSlice(allocator);
}

test "tokenizes simple" {
    const str = "const number = 42;";
    const tokens = try tokenize(std.testing.allocator, str);
    defer {
        for (tokens) |t| {
            std.testing.allocator.free(t);
        }
        std.testing.allocator.free(tokens);
    }

    const expected = &[_][]const u8{ "const", " ", "number", " ", "=", " ", "42", ";" };
    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

test "tokenizes code" {
    const str =
        \\const std = @import("std");
        \\
        \\pub fn main() !void {
        \\  const tall: u8 = 42;
        \\  var nummer = 0;
        \\  nummer += 1;
        \\
        \\  const streng = "Zig";
        \\  const str: []const u8 = "Intro";
        \\
        \\  std.debug.print("Hello, World!\n");
        \\}
    ;
    const tokens = try tokenize(std.testing.allocator, str);
    defer {
        for (tokens) |t| {
            std.testing.allocator.free(t);
        }
        std.testing.allocator.free(tokens);
    }

    const expected = &[_][]const u8{
        "const",
        " ",
        "std",
        " ",
        "=",
        " ",
        "@import",
        "(",
        "\"std\"",
        ")",
        ";",
        "\n",
        "\n",
        "pub",
        " ",
        "fn",
        " ",
        "main",
        "(",
        ")",
        " ",
        "!",
        "void",
        " ",
        "{",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "tall",
        ":",
        " ",
        "u8",
        " ",
        "=",
        " ",
        "42",
        ";",
        "\n",
        " ",
        " ",
        "var",
        " ",
        "nummer",
        " ",
        "=",
        " ",
        "0",
        ";",
        "\n",
        " ",
        " ",
        "nummer",
        " ",
        "+=",
        " ",
        "1",
        ";",
        "\n",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "streng",
        " ",
        "=",
        " ",
        "\"Zig\"",
        ";",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "str",
        ":",
        " ",
        "[",
        "]",
        "const",
        " ",
        "u8",
        " ",
        "=",
        " ",
        "\"Intro\"",
        ";",
        "\n",
        "\n",
        " ",
        " ",
        "std.debug.print",
        "(",
        "\"Hello, World!\\n\"",
        ")",
        ";",
        "\n",
        "}",
    };

    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

test "tokenizes comments too" {
    const str =
        \\// comment
        \\const n = 1;
    ;
    const tokens = try tokenize(std.testing.allocator, str);
    defer {
        for (tokens) |t| {
            std.testing.allocator.free(t);
        }
        std.testing.allocator.free(tokens);
    }

    const expected = &[_][]const u8{ "// comment\n", "const", " ", "n", " ", "=", " ", "1", ";" };
    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

pub fn tokenize2(allocator: Allocator, s: []const u8) ![][]const u8 {
    var tokens = try ArrayList([]const u8).initCapacity(allocator, 0);

    var start: usize = 0;
    var i: usize = 0;
    while (getChar(i, s)) |c| : (i += 1) {
        if (isWhitespace(c) or isDelimiter(c)) {
            if (start != i) {
                try tokens.append(allocator, s[start..i]);
            }

            const next = i + 1;
            try tokens.append(allocator, s[i..next]);
            start = next;
        } else if (c == '"') {
            i += 1;
            while (getChar(i, s)) |sc| : (i += 1) {
                if (sc == '"' and getChar(i - 1, s) != '\\') {
                    const next = i + 1;
                    try tokens.append(allocator, s[start..next]);
                    start = next;
                    break;
                }
            }
        } else if (c == '/' and getChar(i + 1, s) == '/') {
            i += 2;
            while (getChar(i, s)) |sc| : (i += 1) {
                if (sc == '\n') {
                    const next = i + 1;
                    try tokens.append(allocator, s[start..next]);
                    start = next;
                    break;
                }
            }
        } else if (c == '#') {
            i += 1;
            while (getChar(i, s)) |sc| : (i += 1) {
                if (sc == '\n') {
                    const next = i + 1;
                    try tokens.append(allocator, s[start..next]);
                    start = next;
                    break;
                }
            }
        }
    }

    if (start < s.len) {
        try tokens.append(allocator, s[start..]);
    }

    return tokens.toOwnedSlice(allocator);
}

test "tokenizes simple 2" {
    const str = "const number = 42;";
    const tokens = try tokenize2(std.testing.allocator, str);
    defer std.testing.allocator.free(tokens);

    const expected = &[_][]const u8{ "const", " ", "number", " ", "=", " ", "42", ";" };
    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

test "tokenizes code 2" {
    const str =
        \\const std = @import("std");
        \\
        \\pub fn main() error.AAH!void {
        \\  const tall: u8 = 42;
        \\  var nummer = 0;
        \\  nummer += 1;
        \\
        \\  const streng = "Zig";
        \\  const str: []const u8 = "Intro";
        \\
        \\  std.debug.print("Hello, World!\n");
        \\}
    ;
    const tokens = try tokenize2(std.testing.allocator, str);
    defer std.testing.allocator.free(tokens);

    const expected = &[_][]const u8{
        "const",
        " ",
        "std",
        " ",
        "=",
        " ",
        "@import",
        "(",
        "\"std\"",
        ")",
        ";",
        "\n",
        "\n",
        "pub",
        " ",
        "fn",
        " ",
        "main",
        "(",
        ")",
        " ",
        "error.AAH",
        "!",
        "void",
        " ",
        "{",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "tall",
        ":",
        " ",
        "u8",
        " ",
        "=",
        " ",
        "42",
        ";",
        "\n",
        " ",
        " ",
        "var",
        " ",
        "nummer",
        " ",
        "=",
        " ",
        "0",
        ";",
        "\n",
        " ",
        " ",
        "nummer",
        " ",
        "+=",
        " ",
        "1",
        ";",
        "\n",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "streng",
        " ",
        "=",
        " ",
        "\"Zig\"",
        ";",
        "\n",
        " ",
        " ",
        "const",
        " ",
        "str",
        ":",
        " ",
        "[",
        "]",
        "const",
        " ",
        "u8",
        " ",
        "=",
        " ",
        "\"Intro\"",
        ";",
        "\n",
        "\n",
        " ",
        " ",
        "std.debug.print",
        "(",
        "\"Hello, World!\\n\"",
        ")",
        ";",
        "\n",
        "}",
    };

    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

test "tokenizes comments too 2" {
    const str =
        \\// comment
        \\const n = 1;
    ;
    const tokens = try tokenize2(std.testing.allocator, str);
    defer std.testing.allocator.free(tokens);

    const expected = &[_][]const u8{ "// comment\n", "const", " ", "n", " ", "=", " ", "1", ";" };
    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}

test "tokenizes markdown headings" {
    const str =
        \\# Heading
        \\const n = 1;
    ;
    const tokens = try tokenize2(std.testing.allocator, str);
    defer std.testing.allocator.free(tokens);

    const expected = &[_][]const u8{ "# Heading\n", "const", " ", "n", " ", "=", " ", "1", ";" };
    try std.testing.expectEqual(expected.len, tokens.len);
    for (expected, tokens) |e, t| {
        try std.testing.expectEqualStrings(e, t);
    }
}
