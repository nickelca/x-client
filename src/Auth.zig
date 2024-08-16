const Self = @This();

name: []const u8,
data: []const u8,

/// Attempt to find auth file, deserialize, and find corresponding entry
/// Caller owns .name and .data
/// TODO: Check for hostname (null & localhost and its addresses & network name are equal)
pub fn fromAuthFile(alloc: std.mem.Allocator, display: Display) !Self {
    const auth_file_path = (try getAuthFilePath(alloc)) orelse return error.AuthFileNotFound;
    defer alloc.free(auth_file_path);

    const auth_entries = try readAuthFile(alloc, auth_file_path);
    defer destroyAuthFileList(alloc, auth_entries);
    const entry = blk: for (auth_entries) |entry| {
        // if no display number, assume it matches any
        if (entry.display_number.len > 0) {
            const display_number = std.fmt.parseInt(u16, entry.display_number, 10) catch
                return error.InvalidAuthFileEntry;
            if (display.display_number.number != display_number) continue :blk;
        }
        break :blk entry;
    } else return error.AuthEntryNotFound;

    return .{
        .name = try alloc.dupe(u8, entry.auth_name),
        .data = try alloc.dupe(u8, entry.auth_data),
    };
}

/// Free .name and .data
pub fn destroy(self: Self, alloc: std.mem.Allocator) void {
    alloc.free(self.name);
    alloc.free(self.data);
}

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

fn readAuthFile(alloc: std.mem.Allocator, path: []const u8) ![]const AuthFileEntry {
    var entries = std.ArrayList(AuthFileEntry).init(alloc);
    errdefer entries.deinit();
    const auth_file = try std.fs.cwd().openFile(path, .{});
    defer auth_file.close();
    const auth_file_reader = auth_file.reader();
    var reader_buffered = std.io.bufferedReader(auth_file_reader);
    const reader = reader_buffered.reader();

    blk: while (true) {
        var entry: AuthFileEntry = undefined;
        entry.family = reader.readInt(u16, .big) catch |err| switch (err) {
            error.EndOfStream => break :blk,
            else => return err,
        };

        const host_address_len = try reader.readInt(u16, .big);
        entry.host_address = try alloc.alloc(u8, host_address_len);
        errdefer alloc.free(entry.host_address);
        const host_address_read = try reader.readAll(entry.host_address);
        if (host_address_read != host_address_len) return error.MalformedAuthFile;

        const display_number_len = try reader.readInt(u16, .big);
        entry.display_number = try alloc.alloc(u8, display_number_len);
        errdefer alloc.free(entry.display_number);
        const display_number_read = try reader.readAll(entry.display_number);
        if (display_number_read != display_number_len) return error.MalformedAuthFile;

        const auth_name_len = try reader.readInt(u16, .big);
        entry.auth_name = try alloc.alloc(u8, auth_name_len);
        errdefer alloc.free(entry.auth_name);
        const auth_name_read = try reader.readAll(entry.auth_name);
        if (auth_name_read != auth_name_len) return error.MalformedAuthFile;

        const auth_data_len = try reader.readInt(u16, .big);
        entry.auth_data = try alloc.alloc(u8, auth_data_len);
        errdefer alloc.free(entry.auth_data);
        const auth_data_read = try reader.readAll(entry.auth_data);
        if (auth_data_read != auth_data_len) return error.MalformedAuthFile;

        try entries.append(entry);
    }

    return entries.toOwnedSlice();
}

fn destroyAuthFileList(alloc: std.mem.Allocator, entries: []const AuthFileEntry) void {
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

const Display = @import("Display.zig");
const common = @import("common.zig");
const builtin = @import("builtin");
const std = @import("std");
