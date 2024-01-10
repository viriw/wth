const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const wth = b.addModule("wth", .{
        .dependencies = &.{},
        .source_file = std.Build.LazyPath.relative("src/wth.zig"),
    });

    // ---

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const example = b.addExecutable(.{
        .name = "wth-example",
        .root_source_file = std.Build.LazyPath.relative("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.addModule("wth", wth);
    b.installArtifact(example);

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/wth.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
