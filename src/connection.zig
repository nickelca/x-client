const base_port = 6000;

/// Connect to X server
pub fn connect(alloc: std.mem.Allocator, display: x.Display) !std.net.Stream {
    return std.net.tcpConnectToHost(alloc, display.host, base_port + display.number);
}

/// Disconnect to X server
pub fn disconnect(sock: std.net.Stream) void {
    sock.close();
}

const std = @import("std");
const x = @import("root.zig");
