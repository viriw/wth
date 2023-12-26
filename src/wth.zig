const builtin = @import("builtin");
const std = @import("std");

const impl = switch (builtin.target.os.tag) {
    .windows => @import("win32/impl.zig"),
    else => @compileError("unsupported platform"),
};

pub const InitError = error{SystemResources};
pub const InitOptions = struct {};

pub fn init(options: InitOptions) InitError!void {
    return try impl.init(options);
}

pub fn deinit() void {
    impl.deinit();
}

pub fn sync() !void {
    return try impl.sync();
}

pub const Window = struct {
    impl: impl.Window,

    pub const CreateError = error{SystemResources} || std.mem.Allocator.Error;
    pub const CreateOptions = struct {};

    pub fn create(allocator: std.mem.Allocator, options: CreateOptions) CreateError!*Window {
        const window = try allocator.create(Window);
        errdefer allocator.destroy(window);
        window.impl.allocator = allocator;
        try window.impl.emplace(options);
        return window;
    }

    pub fn destroy(window: *Window) void {
        const allocator = window.impl.allocator;
        defer allocator.destroy(window);
        window.impl.deinit();
    }
};
