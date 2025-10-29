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

    _ = try splitPages(allocator, content, "---");
    //defer allocator.free(slides);

    // process handling
    var process = try Process.init();
    defer process.deinit();

    var buf: [1]u8 = undefined;
    while (buf[0] != 'q') {
        _ = try process.read(&buf);
        _ = try process.write(&buf);
    }
}
