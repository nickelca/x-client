const native_endian = builtin.cpu.arch.endian();
inline fn writeNativeInt(
    comptime T: type,
    buffer: *[@divExact(@typeInfo(T).Int.bits, 8)]u8,
    value: T,
) void {
    std.mem.writeInt(T, buffer, value, native_endian);
}

fn pad(n: usize) usize {
    return @mod(4 - @mod(n, 4), 4);
}

const std = @import("std");
const builtin = @import("builtin");
