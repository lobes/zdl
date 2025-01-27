const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Static library
    const lib = b.addStaticLibrary(.{
        .name = "ZDL3",
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    lib.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/SDL3" });
    lib.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    lib.linkSystemLibrary("SDL3");
    lib.linkLibC();
    b.installArtifact(lib);

    // Executable
    const exe = b.addExecutable(.{
        .name = "ZDL3",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/SDL3" });
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    exe.linkSystemLibrary("SDL3");
    exe.linkLibC();
    exe.linkLibrary(lib); // Link with our static library
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Add test step
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    unit_tests.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include/SDL3" });
    unit_tests.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    unit_tests.linkSystemLibrary("SDL3");
    unit_tests.linkLibC();

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
