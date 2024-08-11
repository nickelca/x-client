const base_tcp_port = 6000;
const base_fd_path = "/tmp/.X11-unix/X";

pub fn connect(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    switch (display.protocol) {
        .unix => return connectUnix(alloc, display),
        .tcp => return connectTcp(alloc, display),
        .decnet => @panic("Unimplemented."), // TODO: How to connect to DECnet
    }
}

/// Connect to X server via sockets. If the socket is not found, fall back to TCP
pub fn connectUnix(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    return connectFd(alloc, display) catch |err| switch (err) {
        error.FileNotFound => if (display.display_number == .socket_path)
            err
        else
            connectTcp(alloc, display), // We can fall back to TCP if socket was given through display number
        else => err,
    };
}

/// Connect to X server via TCP
/// Asserts display.display_number.number is active
pub fn connectTcp(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    return std.net.tcpConnectToHost(alloc, display.host, base_tcp_port + display.display_number.number);
}

/// Connect to X server via Socket
pub fn connectFd(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    switch (display.display_number) {
        .socket_path => |path| {
            return std.net.connectUnixSocket(path);
        },
        .number => switch (builtin.target.os.tag) {
            .linux => {
                var buf: [std.os.linux.PATH_MAX]u8 = undefined;
                const fd_path = try std.fmt.bufPrint(&buf, base_fd_path ++ "{d}", .{display.number});
                return std.net.connectUnixSocket(fd_path);
            },
            .windows => {
                var buf: [std.os.windows.MAX_PATH]u8 = undefined;
                const fd_path = try std.fmt.bufPrint(&buf, base_fd_path ++ "{d}", .{display.number});
                return std.net.connectUnixSocket(fd_path);
            },
            else => {
                const fd_path = try std.fmt.allocPrint(alloc, base_fd_path ++ "{d}", .{display.number});
                defer alloc.free(fd_path);
                return std.net.connectUnixSocket(fd_path);
            },
        },
    }
}

/// Disconnect from X server
pub fn disconnect(sock: std.net.Stream) void {
    sock.close();
}

const builtin = @import("builtin");
const std = @import("std");
const x = @import("root.zig");
