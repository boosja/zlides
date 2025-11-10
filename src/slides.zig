const std = @import("std");
const Allocator = std.mem.Allocator;

fn getChar(i: usize, s: []const u8) ?u8 {
    return if (i < s.len) s[i] else null;
}

test "get char" {
    const s: []const u8 = "hello\n---\nworld!";
    try std.testing.expect(getChar(5, s) == '\n');
    try std.testing.expect(getChar(6, s) == '-');
    try std.testing.expect(getChar(7, s) == '-');
    try std.testing.expect(getChar(8, s) == '-');
}

fn isDelimiter(delim: []const u8, i: usize, s: []const u8) bool {
    return getChar(i, s) == delim[0] and
        (i + delim.len < s.len) and
        std.mem.eql(u8, delim, s[i .. i + delim.len]);
}

test "is delimiter" {
    const delim = "\n---\n";

    const start_of_str = isDelimiter(delim, 0, "hello\n---\nworld!");
    try std.testing.expect(!start_of_str);

    const delimiter = isDelimiter(delim, 5, "hello\n---\nworld!");
    try std.testing.expect(delimiter);

    const end_of_str = isDelimiter(delim, 15, "hello\n---\nworld!");
    try std.testing.expect(!end_of_str);

    const newline_at_end = isDelimiter(delim, 16, "hello\n---\nworld!\n");
    try std.testing.expect(!newline_at_end);
}

pub fn splitPages(allocator: Allocator, s: []const u8, delimiter: []const u8) ![][]const u8 {
    var pages: std.ArrayList([]const u8) = .empty;

    var start: usize = 0;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (isDelimiter(delimiter, i, s)) {
            try pages.append(allocator, s[start..i]);
            i = i + delimiter.len;
            start = i;
        }
    }

    // append the last page too
    try pages.append(allocator, s[start..]);

    return pages.toOwnedSlice(allocator);
}

test "splits pages" {
    const rawSlides =
        \\Hello world!
        \\---
        \\This is the second slide
        \\---
        \\...and this the third
    ;
    const pages = try splitPages(std.testing.allocator, rawSlides, "\n---\n");
    defer std.testing.allocator.free(pages);

    const expected = &[_][]const u8{
        "Hello world!\n",
        "\nThis is the second slide\n",
        "\n...and this the third",
    };
    for (expected, pages) |e, p| {
        try std.testing.expectEqualStrings(e, p);
    }
}

fn countChar(char: u8, s: []const u8) usize {
    var count: usize = 0;
    for (s) |c| {
        if (c == char) {
            count += 1;
        }
    }

    return count;
}

test "counts chars in string" {
    const s = "This\nis\ncounting\nlines";

    try std.testing.expectEqual(3, countChar('\n', s));
    try std.testing.expectEqual(4, countChar('i', s));
    try std.testing.expectEqual(0, countChar('x', s));
}

pub fn padPages(allocator: Allocator, pages: [][]const u8) ![][]const u8 {
    var biggest: usize = 0;
    for (pages) |s| {
        const newlines = countChar('\n', s);
        if (biggest < newlines) {
            biggest = newlines;
        }
    }

    var newPages: std.ArrayList([]const u8) = try .initCapacity(allocator, pages.len);

    var paddedPage: std.ArrayList(u8) = .empty;
    for (pages) |page| {
        const newlines = countChar('\n', page);
        const diff = biggest - newlines;
        try paddedPage.appendSlice(allocator, page);
        try paddedPage.appendNTimes(allocator, '\n', diff);
        newPages.appendAssumeCapacity(try paddedPage.toOwnedSlice(allocator));
    }

    return newPages.toOwnedSlice(allocator);
}

test "pads pages" {
    const rawSlides =
        \\
        \\Hello world!
        \\---
        \\This is the second slide
        \\
        \\
        \\Large page
        \\---
        \\...and this the third
    ;
    const pages = try splitPages(std.testing.allocator, rawSlides, "\n---\n");
    defer std.testing.allocator.free(pages);

    const paddedPages = try padPages(std.testing.allocator, pages);
    defer {
        for (paddedPages) |p| {
            std.testing.allocator.free(p);
        }
        std.testing.allocator.free(paddedPages);
    }

    for (paddedPages) |p| {
        try std.testing.expectEqual(3, countChar('\n', p));
    }
}

pub fn makeSlides(allocator: Allocator, fileContent: []u8) ![][]const u8 {
    const pages = try splitPages(allocator, fileContent, "\n ---\n");
    // const slides = try padPages(allocator, pages);
    return pages;
}
