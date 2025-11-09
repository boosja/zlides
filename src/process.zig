const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const Allocator = std.mem.Allocator;
const File = std.fs.File;
const posix = std.posix;
const fmt = std.fmt;

const hide_cursor = "\x1b[?25l";
const show_cursor = "\x1b[?25h";
const alt_buffer = "\x1b[?1049h";
const norm_buffer = "\x1b[?1049l";
const clear_buffer = "\x1b[H\x1b[2J";

pub const Process = struct {
    stdin: File,
    stdout: File,
    orig: std.posix.termios,

    pub fn init() !Process {
        const stdin = File.stdin();
        const stdout = File.stdout();
        const orig = try posix.tcgetattr(stdin.handle);

        var raw = orig;
        raw.lflag.ICANON = false;
        raw.lflag.ECHO = false;

        try posix.tcsetattr(stdin.handle, .FLUSH, raw);

        _ = try stdout.write(fmt.comptimePrint("{s}{s}", .{ alt_buffer, hide_cursor }));

        return .{
            .stdin = stdin,
            .stdout = stdout,
            .orig = orig,
        };
    }

    pub fn deinit(self: *Process) void {
        posix.tcsetattr(self.stdin.handle, .FLUSH, self.orig) catch {};
        _ = self.stdout.write(fmt.comptimePrint("{s}{s}", .{ norm_buffer, show_cursor })) catch {};
    }

    pub fn read(self: *Process, buf: []u8) !usize {
        return try self.stdin.read(buf);
    }

    pub fn write(self: *Process, buf: []const u8) !usize {
        return try self.stdout.write(buf);
    }

    pub fn clear(self: *Process) !usize {
        return try self.stdout.write(clear_buffer);
    }
};

const ANSI = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1B[1m";
    pub const red = "\x1b[31m";
    pub const green = "\x1b[32m";
    pub const yellow = "\x1b[33m";
    pub const blue = "\x1b[34m";
    pub const magenta = "\x1b[35m";
    pub const cyan = "\x1b[36m";
};

const Keyword = enum {
    constant,
    public,
    func,
    structure,
    enumerator,
    whether,
    rather,
    yeet,
    tryer,
    catcher,
    dereference,
    compilation,
};

const KeywordMap = std.StaticStringMap(Keyword).initComptime(.{
    .{ "const", .constant },
    .{ "pub", .public },
    .{ "fn", .func },
    .{ "struct", .structure },
    .{ "enum", .enumerator },
    .{ "if", .whether },
    .{ "else", .rather },
    .{ "return", .yeet },
    .{ "try", .tryer },
    .{ "catch", .catcher },
    .{ "defer", .dereference },
    .{ "comptime", .compilation },
});

const Types = enum {
    t_void,
    t_u8,
    t_arrayList,
};

const TypeMap = std.StaticStringMap(Types).initComptime(.{
    .{ "void", .t_void },
    .{ "u8", .t_u8 },
    .{ "std.ArrayList", .t_arrayList },
});

fn isDelimiter(c: u8) bool {
    return switch (c) {
        '(', ')', '[', ']', '{', '}', ',', ':', ';', '*', '!', '?' => true,
        else => false,
    };
}

fn toANSI(token: []const u8) ?[]const u8 {
    if (KeywordMap.get(token)) |_| {
        return ANSI.blue;
    }
    if (TypeMap.get(token)) |_| {
        return ANSI.green;
    }
    if (isDelimiter(token[0])) {
        return ANSI.cyan;
    }
    if (token[0] == '"') {
        return ANSI.yellow;
    }
    if (token[0] == '#') {
        return ANSI.bold;
    }
    if (token.len > 1 and std.mem.eql(u8, token[0..2], "//")) {
        return ANSI.yellow;
    }
    if (std.mem.startsWith(u8, token, "error.")) {
        return ANSI.red;
    }

    return null;
}

test "highlights const token" {
    const highlighted = toANSI("const").?;
    try std.testing.expectEqualStrings("\x1b[34m", highlighted);
}

pub fn highlight(allocator: Allocator, s: []const u8) ![]const u8 {
    const tokens = try tokenizer.tokenize2(allocator, s);
    defer allocator.free(tokens);

    var hl: std.ArrayList([]const u8) = .empty;
    defer hl.deinit(allocator);

    for (tokens) |t| {
        const ansi = toANSI(t);
        if (ansi) |code| {
            try hl.append(allocator, code);
            try hl.append(allocator, t);
            try hl.append(allocator, ANSI.reset);
        } else {
            try hl.append(allocator, t);
        }
    }

    return std.mem.join(allocator, "", hl.items);
}

test "highlight" {
    const code = "const hello = \"world\";";
    const hl = try highlight(std.testing.allocator, code);
    defer std.testing.allocator.free(hl);

    try std.testing.expectEqualStrings("\x1b[34mconst\x1b[0m hello = \"world\";", hl);
}
