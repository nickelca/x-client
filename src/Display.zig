const Self = @This();

protocol: ?Protocol,
host: ?[]const u8,
number: u16,
screen: ?u32, // TODO: What is this? Leave as u32 for now

const Protocol = enum { unix, tcp, inet, inet6 };

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
/// Format: [PROTOCOL/]HOST:DISPLAYNUM[.SCREEN]
/// ex:
///     localhost:10.0
///     -> host: localhost
///     -> displaynum: 10
///     -> screen: 0
pub fn parse(display: []const u8) ParseError!Self {
    var main_parts = std.mem.splitScalar(u8, display, ':');

    const protocol, const host = blk: {
        const proto_and_host = main_parts.next() orelse return ParseError.MalformedInput;
        break :blk try parseLeft(proto_and_host);
    };
    const displaynum, const screen = blk: {
        var displaynum_and_screen = main_parts.next() orelse return ParseError.MissingDisplayNumber;
        if (std.mem.eql(u8, displaynum_and_screen, "")) {
            displaynum_and_screen = main_parts.next() orelse return ParseError.MissingDisplayNumber;
        }
        if (std.mem.eql(u8, displaynum_and_screen, "")) {
            return ParseError.MissingDisplayNumber;
        }
        break :blk try parseRight(displaynum_and_screen);
    };
    return .{
        .protocol = protocol,
        .host = host,
        .num = displaynum,
        .screen = screen,
    };
}

fn parseLeft(proto_and_host: []const u8) !struct { ?[]const u8, ?[]const u8 } {
    var itt = std.mem.splitScalar(u8, proto_and_host, '/');
    const proto = itt.next() orelse null;
    const host = itt.next() orelse null;
    if (itt.next()) return ParseError.MalformedInput;
    return .{ proto, host };
}

fn parseRight(displaynum_and_screen: []const u8) !struct { u16, ?u32 } {
    var itt = std.mem.splitScalar(u8, displaynum_and_screen, '.');
    const displaynum_s = itt.next() orelse return ParseError.MissingDisplayNumber;
    const screen_s = itt.next();
    if (itt.next()) return ParseError.MalformedInput;
    const displaynum = std.fmt.parseInt(u16, displaynum_s, 10) catch {
        return ParseError.InvalidDisplayNumber;
    };
    const screen = if (screen_s) std.fmt.parseInt(u32, screen_s, 10) catch {
        return ParseError.InvalidScreenNumber;
    } else null;
    return .{ displaynum, screen };
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
