const std = @import("std");
const Process = @import("process.zig").Process;
const splitPages = @import("slides.zig").splitPages;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filepath = args[1];

    const content = try std.fs.cwd().readFileAlloc(allocator, filepath, 1024);
    //defer allocator.free(content);

    const slides = try splitPages(allocator, content, "---");
    //defer allocator.free(slides);

    // process handling
    var process = try Process.init();
    defer process.deinit();

    var page: usize = 0;
    var cmd_buf: [1]u8 = .{'^'}; // or "^".*
    while (true) {
        const cmd = cmd_buf[0];

        const newPage: usize, const status: Status =
            switch (cmd) {
                '^' => .{ page, .OK },
                'j' => if (page + 1 < slides.len) .{ page + 1, .OK } else .{ page, .LAST_SLIDE },
                'q' => break,
                else => .{ page, .NOOP },
            };

        page = newPage;
        _ = status;

        _ = try process.clear();
        _ = try process.write(slides[page]);
        _ = try process.write("\n");

        _ = try process.read(&cmd_buf);
    }
}

const Status = enum { OK, LAST_SLIDE, NOOP };

