pub const Error = error{
    alloc,
    colormap,
    cursor,
    id_choice,
    match,
    pixmap,
    value,
    window,
};

/// Create a createWindow payload from a provided buffer to be sent to XServer
pub fn createBuf(
    buf: []u8,
    window_id: x11.Window,
    parent_window_id: x11.Window,
    class: x11.Window.Class,
    depth: u8,
    visual: x11.VisualId,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    options: x11.Window.Options,
) Error![]const u8 {
    buf[0] = @intFromEnum(opcode.Major.create_window);
    buf[1] = depth;
    // buf[2..4] is request length. Skip for now
    common.writeNativeInt(u32, buf[4..8], @intFromEnum(window_id));
    common.writeNativeInt(u32, buf[8..12], @intFromEnum(parent_window_id));
    common.writeNativeInt(i16, buf[12..14], x);
    common.writeNativeInt(i16, buf[14..16], y);
    common.writeNativeInt(u16, buf[16..18], width);
    common.writeNativeInt(u16, buf[18..20], height);
    common.writeNativeInt(u16, buf[20..22], border_width);
    common.writeNativeInt(u16, buf[22..24], @intFromEnum(class));
    common.writeNativeInt(u32, buf[24..28], @intFromEnum(visual));
    _ = options; // TODO: figure out how to encode this
    unreachable; // not implemented
}

/// Create a createWindow payload to be sent to XServer
/// Returned slice is owned by caller
pub fn createAlloc(
    alloc: std.mem.Allocator,
    window_id: x11.Window,
    parent_window_id: x11.Window,
    class: x11.Window.Class,
    depth: u8,
    visual: x11.VisualId,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    options: x11.Window.Options,
) Error![]const u8 {
    var buf = std.ArrayList(u8).init(alloc);
    const writer = buf.writer();
    try writer.writeByte(@intFromEnum(opcode.Major.create_window));
    try writer.writeByte(depth);
    try writer.writeByteNTimes(0, 2); // buf[2..4] is request length. Leave as zeroes or now
    try writer.writeInt(u32, @intFromEnum(window_id), native_endian);
    try writer.writeInt(u32, @intFromEnum(parent_window_id), native_endian);
    try writer.writeInt(i16, x, native_endian);
    try writer.writeInt(i16, y, native_endian);
    try writer.writeInt(u16, width, native_endian);
    try writer.writeInt(u16, height, native_endian);
    try writer.writeInt(u16, border_width, native_endian);
    try writer.writeInt(u16, @intFromEnum(class), native_endian);
    try writer.writeInt(u32, @intFromEnum(visual), native_endian);
    _ = options; // TODO: figure out how to encode this
    unreachable; // not implemented
}

const native_endian = @import("builtin").cpu.arch.endian();

const opcode = @import("opcode.zig");
const common = @import("common.zig");
const x11 = @import("root.zig");
const std = @import("std");
