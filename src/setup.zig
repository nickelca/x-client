/// Get the length of a setup packet
pub fn length(auth_name_len: u16, auth_data_len: u16) usize {
    var total: usize = 0;
    total += 1; // byte order
    total += 1; // unused
    total += 2; // protocol major version
    total += 2; // protocol minor version
    total += 2; // authorization name length
    total += 2; // authorization data length
    total += 2; // unused
    total += auth_name_len; // authorization name
    total += common.pad(auth_name_len); // authorization name padding
    total += auth_data_len; // authorization data
    total += common.pad(auth_data_len); // authorization data padding
    return total;
}

pub const max_length = length(std.math.maxInt(u16), std.math.maxInt(u16));

/// Write connection setup packet to provided writer
pub fn create(
    writer: anytype,
    protocol: x.Protocol,
    auth: x.Auth,
) !void {
    try writer.writeByte(switch (native_endian) {
        .big => 'B',
        .little => 'l',
    });
    try writer.writeByteNTimes(0, 1); // unused
    try writer.writeInt(u16, protocol.major, native_endian);
    try writer.writeInt(u16, protocol.minor, native_endian);
    const auth_name_len: u16 = @intCast(auth.name.len);
    const name_pad = common.pad(auth_name_len);
    const auth_data_len: u16 = @intCast(auth.data.len);
    const data_pad = common.pad(auth_data_len);
    try writer.writeInt(u16, auth_name_len, native_endian);
    try writer.writeInt(u16, auth_data_len, native_endian);
    try writer.writeByteNTimes(0, 2); // unused
    try writer.writeAll(auth.name);
    try writer.writeByteNTimes(0, name_pad);
    try writer.writeAll(auth.data);
    try writer.writeByteNTimes(0, data_pad);
}

/// Allocate buffer and write connection setup packet to it
pub fn createAlloc(
    alloc: std.mem.Allocator,
    protocol: x.Protocol,
    auth: x.Auth,
) ![]u8 {
    var buf = std.ArrayList(u8).init(alloc);
    errdefer buf.deinit();
    try create(buf.writer(), protocol, auth);
    return try buf.toOwnedSlice();
}

/// Write connection setup packet to provided buffer
/// Asserts that buffer is big enough to hold packet
pub fn createBuf(
    buf: []u8,
    protocol: x.Protocol,
    auth: x.Auth,
) []u8 {
    // TODO: Should this be a panic or error?
    std.debug.assert(buf.len >= length(auth.name.len, auth.data.len));
    var stream = std.io.fixedBufferStream(buf);
    const writer = stream.writer();
    create(writer, protocol, auth) catch
        unreachable; // We know buf is long enough
    return stream.getWritten();
}

/// Create and send the connection setup packet
/// TODO: Find a better response max length
pub fn createAndSendAlloc(
    alloc: std.mem.Allocator,
    server: std.net.Stream,
    protocol: x.Protocol,
    auth: x.Auth,
    /// This will only be populated if error.ConnectionRefused or error.FurtherAuth occurs
    error_info: *Error,
) !Success {
    const payload = try createAlloc(alloc, protocol, auth);
    defer alloc.free(payload);
    try server.writeAll(payload);
    const response_buf = try server.reader().readAllAlloc(alloc, 65536);
    defer alloc.free(response_buf);

    switch (response_buf[0]) {
        0 => {
            error_info.* = .{ .connection_refused = try ConnectionRefused.read(alloc, response_buf) };
            return error.ConnectionRefused;
        },
        1 => return Success.read(alloc, response_buf),
        2 => {
            error_info.* = .{ .further_auth = try FurtherAuth.read(alloc, response_buf) };
            return error.FurtherAuth;
        },
        else => return error.MalformedResponse,
    }
}

pub const Success = struct {
    const BitmapInfo = struct {
        const Value = enum(u8) {
            @"8" = 8,
            @"16" = 16,
            @"32" = 32,
        };
        scanline_unit: Value,
        scanline_pad: Value,
        endian: std.builtin.Endian,
    };
    protocol: x.Protocol,
    vendor: [*:0]u8,
    release_number: u32,
    resource_id: x.ResourceId,
    image_endian: std.builtin.Endian,
    bitmap: BitmapInfo,
    pixmap_formats: [*:null]?x.Format,
    roots: [*:null]?x.Screen,
    motion_buffer_size: u32,
    maximum_request_length: u16,
    min_keycode: x.Key.Code,
    max_keycode: x.Key.Code,

    fn read(alloc: std.mem.Allocator, buf: []const u8) !Success {
        _ = alloc; // autofix
        _ = buf; // autofix
        return undefined;
    }
};

pub const Error = union(enum) {
    connection_refused: ConnectionRefused,
    further_auth: FurtherAuth,

    pub fn destroy(self: Error) void {
        switch (self) {
            inline else => |v| v.destroy(),
        }
    }
};

const ConnectionRefused = struct {
    protocol: x.Protocol,
    reason: []const u8,

    fn read(alloc: std.mem.Allocator, buf: []const u8) !ConnectionRefused {
        var response: ConnectionRefused = undefined;
        const reason = try alloc.alloc(u8, buf[1]);
        response.protocol.major = std.mem.readInt(u16, buf[2..4], native_endian);
        response.protocol.minor = std.mem.readInt(u16, buf[4..6], native_endian);
        @memcpy(reason, buf[8..][0..reason.len]);
        response.reason = reason;
        return response;
    }

    fn destroy(self: ConnectionRefused, alloc: std.mem.Allocator) void {
        alloc.free(self.reason);
    }
};

const FurtherAuth = struct {
    reason: []const u8,

    fn read(alloc: std.mem.Allocator, buf: []const u8) !FurtherAuth {
        std.debug.print("{d}\n", .{buf});
        var response: FurtherAuth = undefined;
        const max_len = std.mem.readInt(u16, buf[6..8], native_endian) * 4;
        const rest = buf[8..][0..max_len];
        // `n` is not explicitly given. Best thing we can do is treat reason as
        // null-terminated. Nothing I can do if we end up with garbage bytes
        const len = std.mem.indexOfScalar(u8, rest, 0) orelse max_len;
        const reason = try alloc.alloc(u8, len);
        @memcpy(reason, rest[0..len]);
        response.reason = reason;
        return response;
    }

    fn destroy(self: FurtherAuth, alloc: std.mem.Allocator) void {
        alloc.free(self.reason);
    }
};

const native_endian = common.native_endian;
const common = @import("common.zig");
const x = @import("root.zig");
const std = @import("std");
