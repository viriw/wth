pub const options = struct {
    pub const multi_window: bool = true;
};

// ---

const builtin = @import("builtin");
const std = @import("std");

const Allocator = std.mem.Allocator;

const impl = if (!builtin.is_test) switch (builtin.target.os.tag) {
    .windows => @import("win32.zig"),
    else => @compileError("platform not implemented"),
} else @import("blank.zig");

// ---

pub const Init_Error = Allocator.Error || error{SystemResources};
pub const Init_Options = struct {};
pub const Sync_Error = Allocator.Error || error{Shutdown};

pub fn clear() void {
    return impl.clear();
}

pub fn deinit() void {
    return impl.deinit();
}

pub fn events() []const Event {
    return impl.events();
}

pub fn get_allocator() Allocator {
    return impl.get_allocator();
}

pub fn init(allocator: Allocator, init_options: Init_Options) Init_Error!void {
    return try impl.init(allocator, init_options);
}

pub fn sync() Sync_Error!void {
    return try impl.sync();
}

// ---

pub const Event = union(enum) {
    focus: if (options.multi_window) *Window else void,
    unfocus: if (options.multi_window) *Window else void,
};

pub const Window = struct {
    impl: impl.Window,

    pub const Create_Error = Allocator.Error || error{SystemResources};
    pub const Create_Options = struct {
        //
    };

    pub const Controls = packed struct {
        border: bool = true,
        close: bool = true,
        minimise: bool = true,
        maximise: bool = true,
        resize: bool = true,
    };
    pub const Coordinate = u15;

    pub fn create(create_options: Create_Options) Create_Error!*Window {
        const allocator = get_allocator();
        const window = try allocator.create(Window);
        errdefer allocator.destroy(window);
        try impl.Window.emplace(&window.impl, create_options);
        return window;
    }

    pub fn destroy(window: *Window) void {
        defer get_allocator().destroy(window);
        window.impl.deinit();
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
