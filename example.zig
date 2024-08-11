pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    try x.conn.wsaStartup();
    defer x.conn.wsaCleanup();

    const display = try x.Display.fromEnvVar(alloc);
    defer display.destroy(alloc);
    const socket = try x.conn.connect(alloc, display);
    defer x.conn.disconnect(socket);
}

const x = @import("src/root.zig");
const std = @import("std");
