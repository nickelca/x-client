pub const Window = enum(u32) {
    _,
    pub const Gravity = enum(u16) {
        unmap = 0,
        north_west = 1,
        north = 2,
        north_east = 3,
        west = 4,
        center = 5,
        east = 6,
        south_west = 7,
        south = 8,
        south_east = 9,
        static = 10,
    };

    pub const Class = enum(u16) {
        copy_from_parent = 0,
        input_output = 1,
        input_only = 2,
    };

    pub const Options = struct {
        bg_pixmap: BgPixmap = .none,
        bg_pixel: ?u32 = null, // TODO: What is this
        border_pixmap: BorderPixmap = .copy_from_parent,
        border_pixel: ?u32 = null, // TODO: What is this
        bit_gravity: BitGravity = .forget,
        win_gravity: Gravity = .north_west,
        backing_store: BackingStore = .not_useful,
        backing_planes: u32 = 0xffffffff, // TODO: What is this
        backing_pixel: u32 = 0, // TODO: What is this
        override_redirect: bool = false,
        save_under: bool = false,
        events: event.Flags = .{},
        dont_propagate: u32 = 0, // TODO: What is this
        colormap: Colormap = .copy_from_parent,
        cursor: Cursor = .none,
    };
};

pub const BgPixmap = enum(u32) { none = 0, copy_from_parent = 1, _ };
pub const BorderPixmap = enum(u32) { copy_from_parent = 0, _ };
pub const BackingStore = enum(u32) { not_useful = 0, when_mapped = 1, always = 2 };
pub const Pixmap = enum(u32) { _ };
pub const Cursor = enum(u32) { none = 0, _ };
pub const Font = enum(u32) { _ };
pub const GContext = enum(u32) { _ };
pub const Colormap = enum(u32) { copy_from_parent = 0, _ };

pub const Drawable = union(enum) {
    window: Window,
    pixmap: Pixmap,
};

pub const Fontable = union(enum) {
    window: Font,
    pixmap: GContext,
};

pub const VisualId = enum(u32) {
    copy_from_parent = 0,
    _,
};

pub const BitGravity = enum {
    forget,
    static,
    north_west,
    north,
    north_east,
    west,
    center,
    east,
    south_west,
    south,
    south_east,
};

pub const PointerEvent = packed struct(u32) {
    button_press: bool = false,
    button_release: bool = false,
    enter_window: bool = false,
    leave_window: bool = false,
    pointer_motion: bool = false,
    pointer_motion_hint: bool = false,
    button1_motion: bool = false,
    button2_motion: bool = false,
    button3_motion: bool = false,
    button4_motion: bool = false,
    button5_motion: bool = false,
    button_motion: bool = false,
    keymap_state: bool = false,
    _pad: u19 = 0,
};

pub const DeviceEvent = packed struct(u32) {
    key_press: bool = false,
    key_release: bool = false,
    button_press: bool = false,
    button_release: bool = false,
    pointer_motion: bool = false,
    button1_motion: bool = false,
    button2_motion: bool = false,
    button3_motion: bool = false,
    button4_motion: bool = false,
    button5_motion: bool = false,
    button_motion: bool = false,
    _pad: u21 = 0,
};

pub const Key = struct {
    pub const Sym = enum(u32) { _ };
    pub const Code = enum(u8) { _ };
    pub const Mask = packed struct(u32) {
        shift: bool = false,
        lock: bool = false,
        control: bool = false,
        mod1: bool = false,
        mod2: bool = false,
        mod3: bool = false,
        mod4: bool = false,
        mod5: bool = false,
        _pad: u24 = 0,
    };
};

pub const Button = enum(u8) {
    _,
    pub const Mask = packed struct(u32) {
        button1: bool = false,
        button2: bool = false,
        button3: bool = false,
        button4: bool = false,
        button5: bool = false,
        _pad: u27 = 0,
    };
};

pub const KeyButMask = union(enum) {
    key: Key.Mask,
    button: Button.Mask,
};

pub const Point = packed struct {
    x: i16,
    y: i16,
};

pub const Rectangle = packed struct {
    /// upper left corner
    x: i16,
    y: i16,
    width: u16,
    height: u16,
};

pub const Arc = packed struct {
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    angle1: i16,
    angle2: i16,
};

pub const Host = packed struct {
    pub const Family = enum {
        internet,
        internet_v6,
        server_interpreted,
        dec_net,
        chaos,
    };
    pub const Address = [*]u8;
};

pub const Error = error{
    access,
    alloc,
    atom,
    colormap,
    cursor,
    drawable,
    font,
    gcontext,
    id_choice,
    implementation,
    length,
    match,
    name,
    pixmap,
    request,
    value,
    window,
};

pub const Protocol = struct {
    major: u16,
    minor: u16,
};

const ResourceId = struct { base: u32, mask: u32 };

pub const Format = struct {
    depth: u8,
    bits_per_pixel: enum(u8) { @"1" = 1, @"4" = 4, @"8" = 8, @"16" = 16, @"24" = 24, @"32" = 32 },
    scanline_pad: enum(u8) { @"8" = 8, @"16" = 16, @"32" = 32 },
};

pub const Depth = struct {
    depth: u8,
    visuals: [*:null]?VisualType,
};

pub const VisualType = struct {
    id: VisualId,
    class: enum { static_gray, static_color, true_color, gray_scale, pseudo_color, direct_color },
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    colormap_entries: u16,
};

pub const Screen = struct {
    root: Window,
    width_in_pixels: u16,
    height_in_pixels: u16,
    width_in_mm: u16,
    height_in_mm: u16,
    allowed_depths: [*:null]?Depth,
    root_depth: u8,
    root_visual: VisualId,
    default_colormap: Colormap,
    white_pixel: u32,
    black_pixel: u32,
    min_installed_maps: u16,
    max_installed_maps: u16,
    backing_stores: enum { never, when_mapped, always },
    save_unders: bool,
    current_input_masks: event.Flags,
};

pub fn sendAlloc(alloc: std.mem.Allocator, server: std.net.Stream, payload: []const u8) ![]const u8 {
    try server.writeAll(payload);
    return server.reader().readAllAlloc(alloc, 5096);
}

pub fn sendBuf(response_buf: []u8, server: std.net.Stream, payload: []const u8) ![]const u8 {
    try server.writeAll(payload);
    const read = try server.readAll(response_buf);
    return response_buf[0..read];
}

pub const Display = @import("Display.zig");
pub const Atom = @import("atom.zig").Atom;
pub const event = @import("event.zig");
pub const Auth = @import("Auth.zig");

pub const conn = @import("connection.zig");
pub const auth = @import("auth.zig");
pub const setup = @import("setup.zig");
pub const create_window = @import("create_window.zig");

const common = @import("common.zig");
const std = @import("std");
const builtin = @import("builtin");

const Self = @This();
test Self {
    std.testing.refAllDeclsRecursive(Self);
}
