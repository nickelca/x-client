const Self = @This();

protocol: ?Protocol,
host: ?[]const u8,
display_number: DisplayNumber,
screen: ?u32,

const DisplayNumber = union(enum) {
    number: u16,
    socket_path: []const u8,
};
const Protocol = enum { unix, tcp, decnet };

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
/// Parse a display name into a Display struct
/// Strings in the struct are slices into `display`
/// General Format: [HOST]:DISPLAYNUM[.SCREEN]
/// ex:
///     localhost:10.0
///     :0
///     :14.3
///     x.org:0
/// DECnet Format:  NODENAME::DISPLAYNUM[.SCREEN]
/// ex:
///     myws::0
///     hydra::2.1
/// Unix Domain Socket Format:  unix:SOCKETPATH
///                             unix:DISPLAYNUM.SCREEN
/// ex:
///     unix:/tmp/.X11-unix/0
///     unix:/chicken/a
///     unix:1.0
/// Unix Domain Socket format is non-standard and may be incorrect
pub fn parse(display: []const u8) ParseError!Self {
    var itt = std.mem.splitScalar(u8, display, ':');
    const first = itt.next() orelse return ParseError.MalformedInput;
    const second = itt.next() orelse return ParseError.MalformedInput;
    const third = itt.next();
    if (itt.next() != null) return ParseError.MalformedInput;

    const host = if (std.mem.eql(u8, first, "")) null else first;
    const protocol = if (third != null) .decnet else determineProtocol(host);
    const displaynum_and_screen = third orelse second;
    const displaynum, const screen = try parseRight(
        displaynum_and_screen,
        !(protocol != .unix or host == null),
    );

    return .{
        .host = host,
        .protocol = protocol,
        .display_number = displaynum,
        .screen = screen,
    };
}

fn parseRight(str: []const u8, path_allowed: bool) ParseError!struct { DisplayNumber, ?u32 } {
    var itt = std.mem.splitScalar(u8, str, '.');
    const displaynum_s = itt.next() orelse return ParseError.MissingDisplayNumber;
    const screen_s_opt = itt.next();
    if (std.mem.eql(u8, displaynum_s, "")) return ParseError.MissingDisplayNumber;
    const displaynum_opt = std.fmt.parseInt(u16, displaynum_s, 10) catch blk: {
        if (!path_allowed) return ParseError.InvalidDisplayNumber;
        break :blk null;
    };
    const screen = blk: {
        if (displaynum_opt == null) break :blk null;
        break :blk if (screen_s_opt) |screen_s|
            std.fmt.parseInt(u32, screen_s, 10) catch return error.InvalidScreenNumber
        else
            null;
    };
    if (displaynum_opt) |displaynum| {
        return .{ .{ .number = displaynum }, screen };
    } else {
        return .{ .{ .socket_path = str }, null };
    }
}

fn determineProtocol(host: ?[]const u8) Protocol {
    if (host) |str| {
        if (std.mem.eql(u8, str, "unix")) return .unix;
        return .tcp;
    }
    // determine most optimal communication form
    return switch (builtin.os.tag) {
        .linux => .unix,
        else => .tcp,
    };
}

/// Get DISPLAY environment variable and parse it into a Display struct
/// Must be destroyed with .destroy
pub fn fromEnvVar(alloc: std.mem.Allocator) !Self {
    var sfa = std.heap.stackFallback(1024, alloc);
    const sfa_alloc = sfa.get();
    const display_string = try getEnvVar(sfa_alloc);
    defer sfa_alloc.free(display_string);
    var disp = try parse(display_string);
    if (disp.host) |host| {
        disp.host = try alloc.dupe(u8, host);
    }
    switch (disp.display_number) {
        .socket_path => |path| disp.display_number = try alloc.dupe(u8, path),
        else => {},
    }
    return disp;
}

/// Destroy a Display name created with .fromEnvVar
pub fn destroy(self: Self, alloc: std.mem.Allocator) void {
    if (self.host) |host| {
        alloc.free(host);
    }
    switch (self.display_number) {
        .socket_path => |path| alloc.free(path),
        else => {},
    }
}

fn compare(a: Self, b: Self) bool {
    // std.debug.print("a: {any}\n", .{a});
    // std.debug.print("b: {any}\n", .{b});
    // std.debug.print("\n", .{});
    if (a.protocol != b.protocol or
        a.screen != b.screen) return false;

    switch (a.display_number) {
        .number => |a_num| {
            switch (b.display_number) {
                .number => |b_num| {
                    if (a_num != b_num) return false;
                },
                .socket_path => return false,
            }
        },
        .socket_path => |a_path| {
            switch (b.display_number) {
                .number => return false,
                .socket_path => |b_path| {
                    if (!std.mem.eql(u8, a_path, b_path)) return false;
                },
            }
        },
    }

    if (a.host) |a_host| {
        if (b.host) |b_host| {
            return std.mem.eql(u8, a_host, b_host);
        }
        return false;
    } else {
        return b.host == null;
    }
}

test parse {
    const testing = std.testing;
    try testing.expectError(ParseError.MalformedInput, parse(":::"));
    try testing.expectError(ParseError.MissingDisplayNumber, parse("localhost:"));
    try testing.expectError(ParseError.MissingDisplayNumber, parse(":"));
    try testing.expectError(ParseError.MissingDisplayNumber, parse("myws::"));

    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":a"));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":0a"));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":0a."));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":0a.0"));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":1x"));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":1x."));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse(":1x.10"));
    try testing.expectError(ParseError.InvalidDisplayNumber, parse("192.168.0.1:/tmp/.X11-unix/X0"));

    try testing.expectError(ParseError.InvalidScreenNumber, parse(":1.x"));
    try testing.expectError(ParseError.InvalidScreenNumber, parse(":1.0x"));

    try testing.expect(compare(
        try parse("host:123.456"),
        .{ .protocol = .tcp, .host = "host", .display_number = .{ .number = 123 }, .screen = 456 },
    ));
    try testing.expect(compare(
        try parse(":123.456"),
        .{ .protocol = .unix, .host = null, .display_number = .{ .number = 123 }, .screen = 456 },
    ));
    try testing.expect(compare(
        try parse(":123"),
        .{ .protocol = .unix, .host = null, .display_number = .{ .number = 123 }, .screen = null },
    ));
    try testing.expect(compare(
        try parse("localhost:43"),
        .{ .protocol = .tcp, .host = "localhost", .display_number = .{ .number = 43 }, .screen = null },
    ));

    try testing.expect(compare(
        try parse("unix:/tmp/.x11-unix/x0"),
        .{ .protocol = .unix, .host = "unix", .display_number = .{ .socket_path = "/tmp/.x11-unix/x0" }, .screen = null },
    ));
    try testing.expect(compare(
        try parse("unix:0"),
        .{ .protocol = .unix, .host = "unix", .display_number = .{ .number = 0 }, .screen = null },
    ));
    try testing.expect(compare(
        try parse("unix:2.3"),
        .{ .protocol = .unix, .host = "unix", .display_number = .{ .number = 2 }, .screen = 3 },
    ));

    try testing.expect(compare(
        try parse("myws::0"),
        .{ .protocol = .decnet, .host = "myws", .display_number = .{ .number = 0 }, .screen = null },
    ));
    try testing.expect(compare(
        try parse("hydra::2.1"),
        .{ .protocol = .decnet, .host = "hydra", .display_number = .{ .number = 2 }, .screen = 1 },
    ));
}

const builtin = @import("builtin");
const std = @import("std");
