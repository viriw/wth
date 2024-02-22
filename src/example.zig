const std = @import("std");
const wth = @import("wth");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try wth.init(allocator, .{});
    defer wth.deinit();

    const window = try wth.Window.create(.{});
    defer window.destroy();

    window.set_corner_rounding_mode(.none);

    main: while (true) {
        for (wth.events()) |event| {
            std.debug.print("> {any}\n", .{event});
            if (event == .close_request) {
                break :main;
            }
        }
        wth.clear();

        // ...

        try wth.sync();
    }

    std.debug.print("goodbye\n", .{});
}
