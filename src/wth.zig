const builtin = @import("builtin");
const std = @import("std");

const impl = switch (builtin.target.os.tag) {
    .windows => @import("win32/impl.zig"),
    else => @compileError("unsupported platform"),
};

pub const InitError = error{SystemResources};
pub const InitOptions = struct {};

pub fn init(init_options: InitOptions) InitError!void {
    return try impl.init(init_options);
}

pub fn deinit() void {
    impl.deinit();
}
