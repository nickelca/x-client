pub fn build(b: *std.Build) void {
    const check_exe = b.addExecutable(.{
        .name = "x",
        .root_source_file = b.path("./src/x.zig"),
        .optimize = b.standardOptimizeOption(.{}),
        .target = b.standardTargetOptions(.{}),
    });
    const step = b.step("check", "Check if the code compiles, but emit no binary");
    step.dependOn(&check_exe.step);
}

const std = @import("std");
