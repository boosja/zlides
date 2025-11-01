const std = @import("std");
const Zlides = @import("zlides").Zlides;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const filepath = args[1];

    const content = try std.fs.cwd().readFileAlloc(allocator, filepath, 1024);
    //defer allocator.free(content);

    var zlides = try Zlides.makeFrom(allocator, content);
    try zlides.show();
}
