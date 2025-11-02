//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Allocator = std.mem.Allocator;
const makeSlides = @import("slides.zig").makeSlides;
const Process = @import("process.zig").Process;

pub const Zlides = struct {
    slides: []const []const u8,

    pub fn makeFrom(allocator: Allocator, raw: []u8) !Zlides {
        return .{
            .slides = try makeSlides(allocator, raw),
        };
    }

    pub fn show(self: *Zlides) !void {
        const slides = self.slides;

        var process = try Process.init();
        defer process.deinit();

        var page: usize = 0;
        var cmd_buf: [1]u8 = .{'^'}; // or "^".*
        while (true) {
            const cmd = cmd_buf[0];

            page, const status: Status =
                switch (cmd) {
                    '^' => .{ page, .OK },
                    ' ' => forward(1, page, slides.len),
                    'j' => forward(1, page, slides.len),
                    'J' => forward(5, page, slides.len),

                    'k' => backward(1, page),
                    'K' => backward(5, page),

                    'q' => break,
                    else => .{ page, .NOOP },
                };

            var buf: [7]u8 = undefined;
            const pagination = try std.fmt.bufPrint(&buf, "[{}/{}]", .{ page + 1, slides.len });

            const info = switch (status) {
                .FIRST_SLIDE => " beginning",
                .LAST_SLIDE => " end",
                else => "",
            };

            _ = try process.clear();
            _ = try process.write("\x1b[38;5;240m");
            _ = try process.write(pagination);
            _ = try process.write(info);
            _ = try process.write("\x1b[0m");
            _ = try process.write("\n");
            _ = try process.write(slides[page]);

            _ = try process.read(&cmd_buf);
        }
    }
};

const Status = enum { OK, FIRST_SLIDE, LAST_SLIDE, NOOP };

fn forward(step: usize, page: usize, max: usize) struct { usize, Status } {
    return if (page + step < max) .{ page + step, .OK } else .{ max - 1, .LAST_SLIDE };
}

test "moves slides forward once" {
    try std.testing.expectEqual(.{ 2, .OK }, forward(1, 1, 10));
}
test "moves slides forward 5 pages" {
    try std.testing.expectEqual(.{ 6, .OK }, forward(5, 1, 10));
}
test "moves slides forward to last page" {
    try std.testing.expectEqual(.{ 9, .LAST_SLIDE }, forward(5, 7, 10));
}

fn backward(step: usize, page: usize) struct { usize, Status } {
    return if (0 < page -| step) .{ page - step, .OK } else .{ 0, .FIRST_SLIDE };
}

test "moves slides backward once" {
    try std.testing.expectEqual(.{ 1, .OK }, backward(1, 2));
}
test "moves slides backward 5 pages" {
    try std.testing.expectEqual(.{ 1, .OK }, backward(5, 6));
}
test "moves slides backward to first page" {
    try std.testing.expectEqual(.{ 0, .FIRST_SLIDE }, backward(5, 3));
}

// From zig init:
pub fn bufferedPrint() !void {
    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try stdout.flush(); // Don't forget to flush!
}
