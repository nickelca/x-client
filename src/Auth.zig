name: []const u8,
data: []const u8,

/// Attempt to get the user's X Auth file. If provided through the environment
/// variable XAUTHORITY, the file is assumed to exist.
/// Returned string is owned by caller
pub fn getAuthFilePath(alloc: std.mem.Allocator) !?[]const u8 {
    if (std.process.getEnvVarOwned(alloc, "XAUTHORITY")) |path| {
        return path;
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {},
        else => |e| return e,
    }
    return switch (builtin.os.tag) {
        .windows, .wasi => null, // TODO: default file path on windows?
        else => try getAuthFilePathPosix(alloc),
    };
}

/// Return $HOME/.Xauthority if file exists
/// Returned string is owned by caller
fn getAuthFilePathPosix(alloc: std.mem.Allocator) !?[]const u8 {
    if (std.posix.getenv("HOME")) |home_path| {
        const path = try std.fs.path.join(alloc, &.{ home_path, ".Xauthority" });
        if (std.fs.cwd().access(path, .{})) {
            return path;
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    }
    return null;
}

fn readAuthFile(alloc: std.mem.Allocator, path: []const u8) []const AuthFileEntry {
    var entries = std.ArrayList(AuthFileEntry).init(alloc);
    const auth_file = try std.fs.cwd().openFile(path, .{});
    defer auth_file.close();
    const auth_file_reader = auth_file.reader();
    const reader_buffered = std.io.bufferedReader(auth_file_reader);
    const reader = reader_buffered.reader();

    while (true) {
        var entry: AuthFileEntry = undefined;
        entry.family = try reader.readInt(u16, .big);

        const host_address_len = try reader.readInt(u16, .big);
        entry.host_address = alloc.alloc(u8, host_address_len);
        try reader.readAll(entry.host_address);

        const display_number_len = try reader.readInt(u16, .big);
        entry.display_number = alloc.alloc(u8, display_number_len);
        try reader.readAll(entry.display_number);

        const auth_name_len = try reader.readInt(u16, .big);
        entry.auth_name = alloc.alloc(u8, auth_name_len);
        try reader.readAll(entry.auth_name);

        const auth_data_len = try reader.readInt(u16, .big);
        entry.auth_data = alloc.alloc(u8, auth_data_len);
        try reader.readAll(entry.auth_data);

        try entries.append(entry);
    }

    return entries.toOwnedSlice();
}

fn deinitAuthFileList(alloc: std.mem.Allocator, entries: []const AuthFileEntry) void {
    for (entries) |entry| {
        alloc.free(entry.host_address);
        alloc.free(entry.display_number);
        alloc.free(entry.auth_name);
        alloc.free(entry.auth_data);
    }
    alloc.free(entries);
}

const AuthFileEntry = struct {
    family: u16,
    host_address: []u8,
    display_number: []u8,
    auth_name: []u8,
    auth_data: []u8,
};

const common = @import("common.zig");
const builtin = @import("builtin");
const std = @import("std");
