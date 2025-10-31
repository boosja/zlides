const std = @import("std");
const Process = @import("process.zig").Process;
const splitPages = @import("slides.zig").splitPages;
const padPages = @import("slides.zig").padPages;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filepath = args[1];

    const content = try std.fs.cwd().readFileAlloc(allocator, filepath, 1024);
    //defer allocator.free(content);

    const pages = try splitPages(allocator, content, "---");
    //defer allocator.free(pages);

    const slides = try padPages(allocator, pages);

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
                ' ' => forward(1, page, slides.len),
                'j' => forward(1, page, slides.len),
                'J' => forward(5, page, slides.len),

                'k' => backward(1, page),
                'K' => backward(5, page),

                'q' => break,
                else => .{ page, .NOOP },
            };

        page = newPage;

        _ = try process.clear();
        _ = try process.write(slides[page]);
        _ = try process.write("\n");

        var buf: [7]u8 = undefined;
        const pagination = try std.fmt.bufPrint(&buf, "[{}/{}]", .{ page + 1, slides.len });
        _ = try process.write(pagination);

        const info = switch (status) {
            .FIRST_SLIDE => " beginning",
            .LAST_SLIDE => " end",
            else => "",
        };
        _ = try process.write(info);

        _ = try process.read(&cmd_buf);
    }
}

const Status = enum { OK, FIRST_SLIDE, LAST_SLIDE, NOOP };

fn forward(step: usize, page: usize, max: usize) struct { usize, Status } {
    return if (page + step < max) .{ page + 1, .OK } else .{ max - 1, .LAST_SLIDE };
}

fn backward(step: usize, page: usize) struct { usize, Status } {
    return if (0 < page -| step) .{ page - step, .OK } else .{ 0, .FIRST_SLIDE };
}
