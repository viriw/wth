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

pub const Event = union(enum) {
    close_request: Window.Tag,
    mouse_move: MouseMove,

    pub const MouseMove = struct {
        x: Window.Coordinate,
        y: Window.Coordinate,
        window: Window.Tag,
    };
};

pub const Window = struct {
    impl: impl.Window,

    pub const CreateError = error{SystemResources} || std.mem.Allocator.Error;
    pub const CreateOptions = struct {
        controls: WindowControls = .{},
        class_name: []const u8 = "wth",
        size: [2]Window.Coordinate = .{ 800, 608 },
        title: []const u8 = "a nice window",
    };
    pub const Coordinate = u15;
    pub const Tag = struct {
        impl: if (__flags.multi_window) impl.Window.Tag else void,

        pub fn format(_: Tag, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.writeAll("(opaque)");
        }

        pub fn equal(value: Tag, other_tag: Tag) bool {
            return value.impl.equal(other_tag.impl);
        }
    };

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

    pub fn tag(window: *Window) Window.Tag {
        return window.impl.tag();
    }
};

pub const WindowControls = packed struct {
    border: bool = true,
    close: bool = true,
    minimize: bool = true,
    maximize: bool = true,
    resize: bool = true,
};
