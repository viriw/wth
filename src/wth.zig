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
    close_request: *Window,
    mouse_move: MouseMove,

    pub const MouseMove = struct {
        x: Window.Coordinate,
        y: Window.Coordinate,
        window: *Window,
    };
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
