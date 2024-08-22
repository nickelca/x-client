pub const native_endian = builtin.cpu.arch.endian();

pub inline fn writeNativeInt(
    comptime T: type,
    buffer: *[@divExact(@typeInfo(T).Int.bits, 8)]u8,
    value: T,
) void {
    std.mem.writeInt(T, buffer, value, native_endian);
}

pub fn pad(n: usize) usize {
    return @mod(4 - @mod(n, 4), 4);
}

pub fn readStruct(comptime T: type, reader: anytype) !T {
    const fields = comptime std.meta.fields(T);
    var res: T = undefined;
    inline for (fields) |field| {
        @field(res, field.name) = switch (@typeInfo(field.type)) {
            .Int => try reader.readInt(field.type, native_endian),
            .Struct => try readStruct(field.type, reader),
            .Enum => @enumFromInt(try reader.readInt(
                @typeInfo(field.type).Enum.tag_type,
                native_endian,
            )),
            .Float => @bitCast(try reader.readBytes(@sizeOf(field.type))),
            else => unreachable,
        };
    }
    return res;
}

const std = @import("std");
const builtin = @import("builtin");
