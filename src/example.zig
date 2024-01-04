const std = @import("std");
const wth = @import("wth");

fn resize_hook_example1(
    _: @Vector(2, wth.Window.Coordinate),
    new: @Vector(2, wth.Window.Coordinate),
    direction: wth.Window.ResizeDirection,
) @Vector(2, wth.Window.Coordinate) {
    const base_on_width = switch (direction) {
        .top_left, .left, .right, .bottom_left, .bottom_right, .top_right => true,
        else => false,
    };

    const ratio = 16.0 / 9.0;
    if (base_on_width) {
        const nw: f64 = @floatFromInt(new[0]);
        const nh = nw / ratio;
        return .{ @intFromFloat(nw), @intFromFloat(nh) };
    } else {
        const nh: f64 = @floatFromInt(new[1]);
        const nw = nh * ratio;
        return .{ @intFromFloat(nw), @intFromFloat(nh) };
    }
}

fn resize_hook_example2(
    _: @Vector(2, wth.Window.Coordinate),
    new: @Vector(2, wth.Window.Coordinate),
    direction: wth.Window.ResizeDirection,
) @Vector(2, wth.Window.Coordinate) {
    const base_on_width = switch (direction) {
        .top_left, .left, .right, .bottom_left, .bottom_right, .top_right => true,
        else => false,
    };

    const resolutions = [_][2]u15{
        .{ 800, 608 },
        .{ 896, 504 },
        .{ 1280, 720 },
        .{ 1360, 768 },
        .{ 1366, 768 },
        .{ 1600, 900 },
    };

    var best = @as(u16, 9999);
    var selected = resolutions[0];
    for (resolutions) |resolution| {
        const ix = @intFromBool(!base_on_width);
        const difference = @abs(@as(i16, resolution[ix]) - @as(i16, new[ix]));
        if (difference < best) {
            best = difference;
            selected = resolution;
        }
    }
    return selected;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try wth.init(allocator, .{});
    defer wth.deinit();

    const window = try wth.Window.create(.{ .resize_hook = null, .size = .{ 1280, 720 } });
    defer window.destroy();

    main: while (true) {
        for (wth.events()) |event| {
            std.debug.print("> {any}\n", .{event});
            if (event == .close_request) {
                break :main;
            }
        }
        try wth.sync();
    }

    std.debug.print("goodbye\n", .{});
}
