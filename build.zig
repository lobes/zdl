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

    // Add SDL3 include paths
    lib.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    lib.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/SDL3_ttf" });

    // Add SDL3 library paths
    lib.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    lib.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    // Link SDL3 and SDL3_ttf
    lib.linkSystemLibrary("SDL3");
    lib.linkSystemLibrary("SDL3_ttf");
    lib.linkLibC();
    b.installArtifact(lib);

    // Executable
    const exe = b.addExecutable(.{
        .name = "ZDL3",
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add SDL3 include paths
    exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    exe.addIncludePath(.{ .cwd_relative = "/usr/local/include/SDL3_ttf" });

    // Add SDL3 library paths
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    // Link SDL3 and SDL3_ttf
    exe.linkSystemLibrary("SDL3");
    exe.linkSystemLibrary("SDL3_ttf");
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

    // Add SDL3 include paths for tests
    unit_tests.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    unit_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    unit_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include/SDL3_ttf" });

    // Add SDL3 library paths for tests
    unit_tests.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    unit_tests.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    // Link SDL3 and SDL3_ttf for tests
    unit_tests.linkSystemLibrary("SDL3");
    unit_tests.linkSystemLibrary("SDL3_ttf");
    unit_tests.linkLibC();

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
