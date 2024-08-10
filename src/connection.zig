const base_tcp_port = 6000;
const base_fd_path = "/tmp/.X11-unix/X";

pub fn connect(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    if (display.protocol) |protocol| switch (protocol) {
        .unix => return connectFd(alloc, display),
        .tcp, .inet, .inet6 => return connectTcp(alloc, display),
    };

    if (display.host) |host| {
        // TODO: host == "unix"
        if (host[0] == '/')
            return std.net.connectUnixSocket(host);
        return connectTcp(alloc, display);
    }

    if (builtin.os.tag == .windows) {
        return error.UnspecifiedHostName;
    }

    return connectFd(alloc, display);
}

/// Connect to X server via TCP
pub fn connectTcp(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    return std.net.tcpConnectToHost(alloc, display.host, base_tcp_port + display.number);
}

/// Connect to X server via Socket
pub fn connectFd(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    switch (builtin.target.os.tag) {
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
    }
}

/// Disconnect from X server
pub fn disconnect(sock: std.net.Stream) void {
    sock.close();
}

const builtin = @import("builtin");
const std = @import("std");
const x = @import("root.zig");
