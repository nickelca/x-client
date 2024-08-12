pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    try x.conn.wsaStartup();
    defer x.conn.wsaCleanup() catch {};

    const display = try x.Display.fromEnvVar(alloc);
    defer display.destroy(alloc);
    const server = try x.conn.connect(alloc, display);
    defer x.conn.disconnect(server);

    const setup = try x.setup.createAlloc(
        alloc,
        .{ .major = 11, .minor = 0 },
        .{},
    );
    defer alloc.free(setup);
    const response = try x.sendAlloc(alloc, server, setup);
    defer alloc.free(response);
    std.debug.print("{any}\n", .{response});
}

const x = @import("src/root.zig");
const std = @import("std");
