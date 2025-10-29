const std = @import("std");
const Allocator = std.mem.Allocator;

fn getChar(i: usize, s: []const u8) ?u8 {
    return if (i < s.len) s[i] else null;
}

test "get char" {
    const s: []const u8 = "hello\n---\nworld!";
    try std.testing.expect(getChar(6, s) == '-');
    try std.testing.expect(getChar(7, s) == '-');
    try std.testing.expect(getChar(8, s) == '-');
}

fn isDelimiter(delim: []const u8, i: usize, s: []const u8) bool {
    return (getChar(i, s) == delim[0] and
        std.mem.eql(u8, delim, s[i .. i + delim.len]));
}

test "is delimiter" {
    const delim = "---";
    const str = "hello\n---\nworld!";
    const isDelim1 = isDelimiter(delim, 0, str);
    const isDelim2 = isDelimiter(delim, 6, str);
    const isDelim3 = isDelimiter(delim, 14, str);

    try std.testing.expect(!isDelim1);
    try std.testing.expect(isDelim2);
    try std.testing.expect(!isDelim3);
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
    const pages = try splitPages(std.testing.allocator, rawSlides, "---");
    defer std.testing.allocator.free(pages);

    for (pages) |p| {
        std.debug.print("[start]\n{s}\n[end]\n", .{p});
    }

    const expected = &[_][]const u8{
        "Hello world!\n",
        "\nThis is the second slide\n",
        "\n...and this the third",
    };
    for (expected, pages) |e, p| {
        try std.testing.expectEqualStrings(e, p);
    }
}

pub const Slider = struct {
    slides: [][]const u8,
    page: usize = 0,

    fn next(self: *Slider) ?[]const u8 {
        return if (self.page < self.slides.len - 1) {
            self.page += 1;
            return self.slides[self.page];
        } else null;
    }

    fn prev(self: *Slider) ?[]const u8 {
        return if (0 < self.page) {
            self.page -= 1;
            return self.slides[self.page];
        } else null;
    }

    fn go(self: *Slider, n: usize) ?[]const u8 {
        return if (0 <= n and n < self.slides.len) {
            self.page = n;
            return self.slides[self.page];
        } else null;
    }
};
