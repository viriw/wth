const std = @import("std");
const wth = @import("wth");

pub fn main() void {
    std.debug.print("hello, {s}\n", .{wth.hostname});
}
