const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const wth = b.addModule("wth", .{
        .dependencies = if (builtin.target.os.tag == .windows)
            &.{.{ .name = "zigwin32", .module = b.dependency("zigwin32", .{}).module("zigwin32") }}
        else
            &.{},
        .source_file = std.Build.LazyPath.relative("src/wth.zig"),
    });

    const example = b.addExecutable(.{
        .name = "wth-example",
        .root_source_file = std.Build.LazyPath.relative("src/example.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    example.addModule("wth", wth);
    b.installArtifact(example);
}
