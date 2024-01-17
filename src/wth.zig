pub const options = struct {
    pub const event_buffer_reserve: usize = 32;
    pub const multi_window: bool = true;
    pub const text_input: bool = true;
    pub const win32_fibers: bool = true;
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

pub const Cursor = enum {
    arrow,
    busy, // ⌛
    cross, // +
    hand, // 👆
    i_beam, // I
    move, // ✥
    size_nesw, // ⤢
    size_ns, // ↕
    size_nwse, // ⤡
    size_we, // ↔
    working, // arrow+busy
};

pub const Event = union(enum) {
    close_request: if (options.multi_window) *Window else void,

    focus: if (options.multi_window) *Window else void,
    unfocus: if (options.multi_window) *Window else void,

    mouse_button_press_os: Mouse_Button_OS,
    mouse_button_release_os: Mouse_Button_OS,
    mouse_enter_os: Mouse_Move_OS,
    mouse_leave_os: Mouse_Move_OS,
    mouse_move_os: Mouse_Move_OS,

    pub const Mouse_Button_OS = struct {
        button: Mouse_Button,
        position: @Vector(2, Window.Coordinate),
        window: if (options.multi_window) *Window else void,
    };
    pub const Mouse_Move_OS = struct {
        position: @Vector(2, Window.Coordinate),
        window: if (options.multi_window) *Window else void,
    };
};

pub const Mouse_Button = enum {
    left,
    middle,
    right,
    // TODO: these are grossly windows-specific names
    x1,
    x2,
};

pub const Window = struct {
    impl: impl.Window,

    pub const Create_Error = Allocator.Error || error{SystemResources};
    pub const Create_Options = struct {
        controls: Controls = .{},
        cursor: Cursor = .arrow,
        size: @Vector(2, Window.Coordinate) = .{ 800, 608 },
        title: []const u8 = "hi :3",
        win32_corner_preference: Win32_Corner_Preference = .default,
    };
    pub const Controls = packed struct {
        border: bool = true,
        close: bool = true,
        minimise: bool = true,
        maximise: bool = true,
        resize: bool = true,
    };
    pub const Coordinate = u15;

    pub const Win32_Corner_Preference = @import("win32.zig").Win32_Corner_Preference;

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

    pub fn set_win32_corner_preference(window: *Window, preference: Win32_Corner_Preference) void {
        if (builtin.target.os.tag == .windows) {
            window.impl.set_win32_corner_preference(preference);
        }
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
