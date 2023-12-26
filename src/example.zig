const std = @import("std");
const wth = @import("wth");

pub fn main() !void {
    try wth.init(.{});
    defer wth.deinit();
}
