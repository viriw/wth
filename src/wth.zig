// notes for myself here, i suppose
//
// eventually i will need to care for identical event behaviour across platforms
//
// == first order of business is mouse enter/leave/move etc ==
// when a window spawns under the mouse it gets WM_MOUSEMOVE on windows so we send Enter PLUS it gets a Move on the same coord
// when it leaves it gets a Move + Leave on same coord
// same with alt tabbing etc
// this happens EVEN if its not a move so it emits Enter+Move and Move+Leave with the same coords if you spam alt tab
// right now i don't emit move if it's the same coord as last time. maybe i should? see what X does and also just think about it
//
// == number two ==
// we don't get unfocus() on Window.deinit() i think that's fairly normal

const builtin = @import("builtin");
const std = @import("std");

const __flags = @import("__flags.zig");

const impl = switch (builtin.target.os.tag) {
    .windows => @import("win32/impl.zig"),
    else => @compileError("unsupported platform"),
};

pub const InitError = std.mem.Allocator.Error || error{SystemResources};
pub const InitOptions = struct {};

pub fn init(allocator: std.mem.Allocator, options: InitOptions) InitError!void {
    return try impl.init(allocator, options);
}

pub fn deinit() void {
    impl.deinit();
}

pub fn events() []const Event {
    return impl.events();
}

pub const SyncError = std.mem.Allocator.Error || error{Shutdown};

pub fn sync() SyncError!void {
    return try impl.sync();
}

pub const Cursor = enum {
    Arrow,
    Busy, // ⌛
    Cross, // +
    Hand, // 👆
    IBeam, // I
    Move, // ✥
    SizeNESW, // ⤢
    SizeNS, // ↕
    SizeNWSE, // ⤡
    SizeWE, // ↔
    Working, // arrow+busy
};

pub const Event = union(enum) {
    close_request: if (__flags.multi_window) *Window else void,

    focus: if (__flags.multi_window) *Window else void,
    unfocus: if (__flags.multi_window) *Window else void,

    mouse_enter: MouseMove,
    mouse_leave: MouseMove,

    mouse_button_press_os: MouseClick,
    mouse_button_release_os: MouseClick,
    mouse_move_os: MouseMove,

    pub const MouseClick = struct {
        button: MouseButton,
        position: @Vector(2, Window.Coordinate),
        window: if (__flags.multi_window) *Window else void,
    };
    pub const MouseMove = struct {
        position: @Vector(2, Window.Coordinate),
        window: if (__flags.multi_window) *Window else void,
    };
};

pub const MouseButton = enum {
    left,
    middle,
    right,
    // TODO: these are grossly windows-specific names
    x1,
    x2,
};

pub const Window = struct {
    impl: impl.Window,

    pub const CreateError = error{SystemResources} || std.mem.Allocator.Error;
    pub const CreateOptions = struct {
        class_name: []const u8 = "wth",
        controls: Window.Controls = .{},
        cursor: ?Cursor = Cursor.Arrow,
        resize_hook: ?Window.ResizeHook = null,
        size: @Vector(2, Window.Coordinate) = .{ 800, 608 },
        title: []const u8 = "a nice window",

        // TODO: I think these should be behind builtin.target.os... maybe in a struct of its own for all win32-related ones
        win32_corner_rounding: enum(i32) { default, no, yes, yes_small } = .default,
    };

    pub const Controls = packed struct {
        border: bool = true,
        close: bool = true,
        minimise: bool = true,
        maximise: bool = true,
        resize: bool = true,
    };
    pub const Coordinate = u15;
    pub const ResizeDirection = enum {
        left,
        right,
        top,
        top_left,
        top_right,
        bottom,
        bottom_left,
        bottom_right,
    };
    pub const ResizeHook = *const fn (
        from: @Vector(2, Window.Coordinate),
        to: @Vector(2, Window.Coordinate),
        direction: Window.ResizeDirection,
    ) @Vector(2, Window.Coordinate);

    pub fn create(options: CreateOptions) CreateError!*Window {
        const allocator = impl.getAllocator();
        const window = try allocator.create(Window);
        errdefer allocator.destroy(window);
        try window.impl.emplace(options);
        return window;
    }

    pub fn destroy(window: *Window) void {
        const allocator = impl.getAllocator();
        defer allocator.destroy(window);
        window.impl.deinit();
    }
};
