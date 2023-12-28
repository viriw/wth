const std = @import("std");
const wth = @import("wth");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try wth.init(.{});
    defer wth.deinit();

    const window = try wth.Window.create(allocator, .{});
    defer window.destroy();

    while (true) {
        //std.debug.print("sync! {}\n", .{std.time.nanoTimestamp()});
        try wth.sync();
    }
}
