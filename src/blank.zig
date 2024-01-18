//! Acts as a reference and template for a platform implementation.

const std = @import("std");
const wth = @import("wth.zig");

const Allocator = std.mem.Allocator;

// ---

const global = struct {
    var allocator: Allocator = undefined;
};

pub fn clear() void {
    // _
}

pub fn deinit() void {
    // _
}

pub fn events() []const wth.Event {
    return &.{};
}

pub fn get_allocator() Allocator {
    return global.allocator;
}

pub fn init(allocator: Allocator, init_options: wth.Init_Options) wth.Init_Error!void {
    global.allocator = allocator;
    _ = init_options;
}

pub fn sync() wth.Sync_Error!void {
    // _
}

// ---

pub const Window = struct {
    pub fn emplace(
        window: *Window,
        create_options: wth.Window.Create_Options,
    ) wth.Window.Create_Error!void {
        _ = create_options;
        _ = window;
    }

    pub fn deinit(window: *Window) void {
        _ = window;
    }

    pub fn set_controls(window: *Window, controls: wth.Window.Controls) void {
        _ = window;
        _ = controls;
    }

    pub fn set_size(window: *Window, size: @Vector(2, wth.Window.Coordinate)) void {
        _ = window;
        _ = size;
    }

    pub fn set_visible(window: *Window, visible: bool) void {
        _ = window;
        _ = visible;
    }
};
