pub const Response = struct {
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
};

pub fn createAlloc(
    alloc: std.mem.Allocator,
    protocol: x.Protocol,
    auth: x.Auth,
) ![]u8 {
    var buf = std.ArrayList(u8).init(alloc);
    const writer = buf.writer();
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
    return try buf.toOwnedSlice();
}

const native_endian = common.native_endian;
const common = @import("common.zig");
const x = @import("root.zig");
const std = @import("std");
