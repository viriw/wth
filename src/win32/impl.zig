const builtin = @import("builtin");
const std = @import("std");
const wth = @import("../wth.zig");

const global = struct {
    var main_thread_id: u32 = undefined;
};

inline fn getCurrentThreadId() u32 {
    return switch (builtin.target.cpu.arch) {
        .x86 => asm (
            \\ movl %%fs:0x24, %[id]
            : [id] "=r" (-> u32),
        ),
        .x86_64 => @truncate(asm (
            \\ movq %%gs:0x48, %[id]
            : [id] "=r" (-> u64),
        )),
        else => @compileError("unsupported arch"),
    };
}

pub fn init(_: wth.InitOptions) wth.InitError!void {
    global.main_thread_id = getCurrentThreadId();
}

pub fn deinit() void {
    // .. nothing to do ..
}
