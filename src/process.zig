const std = @import("std");
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
};
