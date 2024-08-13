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

    // const auth = try x.Auth.fromAuthFile(alloc, display);
    // defer auth.destroy(alloc);
    var err_info: x.setup.Error = undefined;
    const response = x.setup.createAndSendAlloc(
        alloc,
        server,
        .{ .major = 11, .minor = 0 },
        .{ .name = &.{}, .data = &.{} },
        &err_info,
    ) catch |err| switch (err) {
        error.ConnectionRefused => {
            std.debug.print(
                \\protocol:{d}.{d}
                \\reason:{s}
                \\extra:{d}
                \\
            , .{
                err_info.connection_refused.protocol.major,
                err_info.connection_refused.protocol.minor,
                err_info.connection_refused.reason,
                err_info.connection_refused.extra_data,
            });
            return err;
        },
        error.FurtherAuth => {
            std.debug.print(
                \\reason:{s}
                \\extra:{d}
                \\
            , .{
                err_info.further_auth.reason,
                err_info.further_auth.extra_data,
            });
            return err;
        },
        else => return err,
    };
    _ = response; // autofix
    // std.debug.print("{any}\n", .{response});
}

const x = @import("src/root.zig");
const std = @import("std");
