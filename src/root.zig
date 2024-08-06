pub const Window = enum(u32) {
    _,
    pub const Gravity = enum {
        unmap,
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

    pub const Class = enum {
        input_output,
        input_only,
        copy_from_parent,
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
        events: Event = .{},
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

pub const Atom = enum(u32) { _ };
pub const VisualId = enum(u32) { _ };

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

pub const Event = packed struct(u32) {
    key_press: bool = false,
    key_release: bool = false,
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
    exposure: bool = false,
    visibility_change: bool = false,
    structure_notify: bool = false,
    resize_redirect: bool = false,
    substructure_notify: bool = false,
    substructure_redirect: bool = false,
    focus_change: bool = false,
    property_change: bool = false,
    colormap_change: bool = false,
    owner_grab_button: bool = false,
    _pad: u7 = 0,

    pub const key_press: u32 = 1 << 0;
    pub const key_release: u32 = 1 << 1;
    pub const button_press: u32 = 1 << 2;
    pub const button_release: u32 = 1 << 3;
    pub const enter_window: u32 = 1 << 4;
    pub const leave_window: u32 = 1 << 5;
    pub const pointer_motion: u32 = 1 << 6;
    pub const pointer_motion_hint: u32 = 1 << 7;
    pub const button1_motion: u32 = 1 << 8;
    pub const button2_motion: u32 = 1 << 9;
    pub const button3_motion: u32 = 1 << 10;
    pub const button4_motion: u32 = 1 << 11;
    pub const button5_motion: u32 = 1 << 12;
    pub const button_motion: u32 = 1 << 13;
    pub const keymap_state: u32 = 1 << 14;
    pub const exposure: u32 = 1 << 15;
    pub const visibility_change: u32 = 1 << 16;
    pub const structure_notify: u32 = 1 << 17;
    pub const resize_redirect: u32 = 1 << 18;
    pub const substructure_notify: u32 = 1 << 19;
    pub const substructure_redirect: u32 = 1 << 20;
    pub const focus_change: u32 = 1 << 21;
    pub const property_change: u32 = 1 << 22;
    pub const colormap_change: u32 = 1 << 23;
    pub const owner_grab_button: u32 = 1 << 24;
    pub const _pad: u32 = 0x7f << 25;
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

pub const Socket = std.io.AnyWriter;

pub fn sendEndianness(conn: Socket) !void {
    const c: u8 = switch (builtin.cpu.arch.endian()) {
        .big => 'B',
        .little => 'l',
    };
    try conn.writeAll(&.{c});
}

pub const Protocol = struct {
    major: u16,
    minor: u16,
};

pub const Auth = struct {
    name: [*:0]u8,
    data: [*:0]u8,
};

const ResourceId = struct { base: u32, mask: u32 };

pub const Format = struct {
    depth: u8,
    bits_per_pixel: enum(u8) { @"1" = 1, @"4" = 4, @"8" = 8, @"16" = 16, @"24" = 24, @"32" = 32 },
    scanline_pad: enum(u8) { @"8" = 8, @"16" = 16, @"32" = 32 },
};

pub const Depth = struct {
    depth: u8,
    visuals: [*:0]VisualType,
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
    allowed_depths: [*:0]Depth,
    root_depth: u8,
    root_visual: VisualId,
    default_colormap: Colormap,
    white_pixel: u32,
    black_pixel: u32,
    min_installed_maps: u16,
    max_installed_maps: u16,
    backing_stores: enum { never, when_mapped, always },
    save_unders: bool,
    current_input_masks: [*]Event,
};

pub const ConnectResponse = struct {
    const BitmapInfo = struct {
        const Value = enum(u8) {
            @"8" = 8,
            @"16" = 16,
            @"32" = 32,
        };
        scanline_unit: Value,
        scanline_pad: Value,
        endian: std.builtin.Endian,
    };
    protocol: Protocol,
    vendor: [*:0]u8,
    release_number: u32,
    resource_id: ResourceId,
    image_endian: std.builtin.Endian,
    bitmap: BitmapInfo,
    pixmap_formats: [*:0]Format,
    roots: [*:0]Screen,
    motion_buffer_size: u32,
    maximum_request_length: u16,
    min_keycode: Key.Code,
    max_keycode: Key.Code,
};

const ConnectError = error{ Failed, Authenticate } || Socket.Error;
pub fn connSetup(
    conn: Socket,
    protocol: Protocol,
    auth: Auth,
    err_payload: void,
) ConnectError!ConnectResponse {
    _ = err_payload; // autofix
    _ = protocol; // autofix
    _ = auth; // autofix
    try conn.writeAll(&.{});
    unreachable; // TODO:
}

/// Get the display environment variable
/// ":0" if not defined
/// Windows sometimes needs to allocate because it's a little silly
pub fn getDisplay(alloc: std.mem.Allocator) ![]const u8 {
    return switch (builtin.os.tag) {
        .windows => std.process.getEnvVarOwned(alloc, "DISPLAY") catch |err| switch (err) {
            error.EnvironmentVariableNotFound => ":0",
            else => err,
        },
        else => std.posix.getenv("DISPLAY") orelse ":0",
    };
}

pub const CreateWindowError = error{
    alloc,
    colormap,
    cursor,
    id_choice,
    match,
    pixmap,
    value,
    window,
};
pub fn createWindow(
    window_id: Window,
    parent_window_id: Window,
    class: Window.Class,
    depth: u8,
    visual: union(enum) {
        id: VisualId,
        copy_from_parent,
    },
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    options: Window.Options,
) CreateWindowError!void {
    _ = options; // autofix
    _ = window_id; // autofix
    _ = parent_window_id; // autofix
    _ = class; // autofix
    _ = depth; // autofix
    _ = visual; // autofix
    _ = x; // autofix
    _ = y; // autofix
    _ = width; // autofix
    _ = height; // autofix
    _ = border_width; // autofix
}

const Self = @This();
test Self {
    std.testing.refAllDeclsRecursive(Self);
}

const std = @import("std");
const builtin = @import("builtin");
