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

    const reader = server.reader();
    const header = try reader.readStruct(Header);
    switch (header.status) {
        .connection_refused => {
            error_info.* = .{
                .connection_refused = try ConnectionRefused.read(alloc, server, header),
            };
            return error.ConnectionRefused;
        },
        .success => return Success.read(alloc, server, header),
        .further_auth => {
            error_info.* = .{
                .further_auth = try FurtherAuth.read(alloc, server, header),
            };
            return error.FurtherAuth;
        },
        else => return error.MalformedResponse,
    }
}

const Header = extern struct {
    status: enum(u8) { connection_refused = 0, success = 1, further_auth = 2, _ },
    /// only used for connection refused
    reason_len: u8,
    /// only used for connection refused and success
    protocol: x.Protocol,
    data_length_in_4byte_blocks: u32,
};

pub const Success = struct {
    const BitmapFormat = struct {
        endian: std.builtin.Endian,
        scanline_unit: u8,
        scanline_pad: u8,
    };
    release_number: u32,
    resource_id: x.ResourceId,
    motion_buffer_size: u32,
    vendor: []const u8,
    maximum_request_length: u16,
    root_screens: []x.Screen,
    pixmap_formats: []x.Format,
    image_endian: std.builtin.Endian,
    bitmap_format: BitmapFormat,
    min_keycode: x.Key.Code,
    max_keycode: x.Key.Code,

    fn read(alloc: std.mem.Allocator, server: std.net.Stream, header: Header) !Success {
        var response: Success = undefined;
        const main_body = try server.reader().readStruct(SuccessBody);
        response.release_number = main_body.release_number;
        response.resource_id = main_body.resource_id;
        response.motion_buffer_size = main_body.motion_buffer_size;
        response.maximum_request_length = main_body.maximum_request_length;
        response.image_endian = switch (main_body.image_byte_order) {
            .lsb_first => .little,
            .msb_first => .big,
            else => return error.MalformedResponse,
        };
        response.bitmap_format = .{
            .endian = switch (main_body.bitmap_format.byte_order) {
                .lsb_first => .little,
                .msb_first => .big,
                else => return error.MalformedResponse,
            },
            .scanline_unit = main_body.bitmap_format.scanline_unit,
            .scanline_pad = main_body.bitmap_format.scanline_pad,
        };
        response.min_keycode = main_body.min_keycode;
        response.max_keycode = main_body.max_keycode;
        const vendor = try alloc.alloc(u8, main_body.vendor_len);
        errdefer alloc.free(vendor);
        if (try server.read(vendor) != vendor.len)
            return error.MalformedResponse;
        // root_screens, pixmap_formats
        _ = header; // autofix
        unreachable; // unimplemented
    }
};

const SuccessBody = packed struct {
    const BitmapFormat = packed struct {
        byte_order: enum(u8) { lsb_first = 0, msb_first = 1, _ },
        scanline_unit: u8,
        scanline_pad: u8,
    };
    release_number: u32,
    resource_id: x.ResourceId,
    motion_buffer_size: u32,
    vendor_len: u32,
    maximum_request_length: u16,
    root_screen_count: u8,
    pixmap_format_count: u8,
    image_byte_order: enum(u8) { lsb_first = 0, msb_first = 1, _ },
    bitmap_format: BitmapFormat,
    min_keycode: x.Key.Code,
    max_keycode: x.Key.Code,
    _unused: u32,
};

pub const Error = union(enum) {
    connection_refused: ConnectionRefused,
    further_auth: FurtherAuth,

    pub fn destroy(self: Error, alloc: std.mem.Allocator) void {
        switch (self) {
            inline else => |v| {
                var reason = v.reason;
                reason.len = v.cap;
                alloc.free(reason);
            },
        }
    }
};

const ConnectionRefused = struct {
    reason: []const u8,
    cap: usize,

    fn read(alloc: std.mem.Allocator, server: std.net.Stream, header: Header) !ConnectionRefused {
        const data_len = @as(usize, header.data_length_in_4byte_blocks) * 4;
        const buf = try alloc.alloc(u8, data_len);
        if (try server.readAll(buf) != buf.len) return error.MalformedResponse;
        return .{
            .cap = buf.len,
            .reason = buf[0..header.reason_len],
        };
    }
};

const FurtherAuth = struct {
    reason: []const u8,
    cap: usize,

    fn read(alloc: std.mem.Allocator, server: std.net.Stream, header: Header) !FurtherAuth {
        const data_len = @as(usize, header.data_length_in_4byte_blocks) * 4;
        const buf = try alloc.alloc(u8, data_len);
        if (try server.readAll(buf) != buf.len) return error.MalformedResponse;
        // `n` is not explicitly given. Best thing we can do is treat reason as
        // null-terminated. Nothing I can do if we end up with garbage bytes
        const len = std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
        return .{
            .reason = buf[0..len],
            .cap = buf.len,
        };
    }
};

const native_endian = common.native_endian;
const common = @import("common.zig");
const x = @import("root.zig");
const std = @import("std");
