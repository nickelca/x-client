const base_tcp_port = 6000;
const base_fd_path = "/tmp/.X11-unix/X";

/// Setup WSA on Windows
/// No-op on non-Windows
pub fn wsaStartup() !void {
    if (builtin.os.tag == .windows) {
        _ = try std.os.windows.WSAStartup(2, 2);
    }
}

/// Cleanup WSA on Windows
/// No-op on non-Windows
pub fn wsaCleanup() !void {
    if (builtin.os.tag == .windows) {
        try std.os.windows.WSACleanup();
    }
}

/// Connect to X server
/// TODO: Sockets on windows?
pub fn connect(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    if (builtin.os.tag == .windows and display.protocol == .unix) return error.UnixNotSupported;
    if (builtin.os.tag == .windows and display.host == null) return error.MissingHost;

    switch (display.protocol) {
        .unix => return connectUnix(alloc, display),
        .tcp => return connectTcp(alloc, display),
        .decnet => return error.DECNetUnimplemented, // TODO: How to connect to DECnet
    }
}

/// Disconnect from X server
pub fn disconnect(sock: std.net.Stream) void {
    sock.close();
}

/// Connect to X server via sockets. If the socket is not found, fall back to TCP
fn connectUnix(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
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
fn connectTcp(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    return std.net.tcpConnectToHost(alloc, display.host orelse "localhost", base_tcp_port + display.display_number.number);
}

/// Connect to X server via Socket
fn connectFd(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    switch (display.display_number) {
        .socket_path => |path| {
            return std.net.connectUnixSocket(path);
        },
        .number => |number| switch (builtin.target.os.tag) {
            .linux => {
                var buf: [std.os.linux.PATH_MAX]u8 = undefined;
                const fd_path = try std.fmt.bufPrint(&buf, base_fd_path ++ "{d}", .{number});
                return std.net.connectUnixSocket(fd_path);
            },
            .windows => {
                var buf: [std.os.windows.MAX_PATH]u8 = undefined;
                const fd_path = try std.fmt.bufPrint(&buf, base_fd_path ++ "{d}", .{number});
                return std.net.connectUnixSocket(fd_path);
            },
            else => {
                const fd_path = try std.fmt.allocPrint(alloc, base_fd_path ++ "{d}", .{number});
                defer alloc.free(fd_path);
                return std.net.connectUnixSocket(fd_path);
            },
        },
    }
}

const builtin = @import("builtin");
const std = @import("std");
const x = @import("root.zig");
