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

const builtin = @import("builtin");
const std = @import("std");
