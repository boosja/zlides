const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filepath = args[1];

    const slides = try std.fs.cwd().readFileAlloc(allocator, filepath, 1024);
    defer allocator.free(slides);

    std.debug.print("{s}\n", .{slides});
}
