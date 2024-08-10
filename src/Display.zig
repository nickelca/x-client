const Self = @This();

protocol: void, // TODO: What is this
host: []const u8,
number: u16,
screen: void, // TODO: What is this

/// Get the display environment variable
/// ":0" if not defined
/// Windows sometimes needs to allocate because it's a little silly
pub fn getEnvVar(alloc: std.mem.Allocator) ![]const u8 {
    return switch (builtin.os.tag) {
        .windows => std.process.getEnvVarOwned(alloc, "DISPLAY") catch |err| switch (err) {
            error.EnvironmentVariableNotFound => ":0",
            else => err,
        },
        else => std.posix.getenv("DISPLAY") orelse ":0",
    };
}

const ParseError = error{
    MalformedInput,
    MissingDisplayNumber,
    InvalidDisplayNumber,
    InvalidScreenNumber,
};
/// Parse a display variable into a Display struct
/// Format: [PROTOCOL/]HOST:DISPLAYNUM[.SCREEN]
/// ex:
///     localhost:10.0
///     -> host: localhost
///     -> displaynum: 10
///     -> screen: 0
pub fn parse(display: []const u8) ParseError!Self {
    _ = display; // autofix
    unreachable; // unimplemented
}

pub fn fromEnvVar(alloc: std.mem.Allocator) !Self {
    const display_string = try getEnvVar(alloc);
    defer if (builtin.os.tag == .windows) alloc.free(display_string);
    return parse(display_string);
}

const builtin = @import("builtin");
const std = @import("std");
