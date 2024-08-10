const Self = @This();

protocol: void, // TODO: What is this
host: []const u8,
number: u16,
screen: void, // TODO: What is this

/// Get the display environment variable
/// ":0" if not defined
/// Returned string must be freed
pub fn getEnvVar(alloc: std.mem.Allocator) ![]const u8 {
    return std.process.getEnvVarOwned(alloc, "DISPLAY") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => alloc.dupe(u8, ":0"),
        else => err,
    };
}

const ParseError = error{
    MalformedInput,
    MissingDisplayNumber,
    InvalidDisplayNumber,
    InvalidScreenNumber,
};
/// Parse a display variable into a Display struct
/// Format: HOST:DISPLAYNUM[.SCREEN]
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
    var sfa = std.heap.stackFallback(1024, alloc);
    const sfa_alloc = sfa.get();
    const display_string = try getEnvVar(sfa_alloc);
    defer sfa_alloc.free(display_string);
    return parse(display_string);
}

const builtin = @import("builtin");
const std = @import("std");
