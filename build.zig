const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Static library
    const lib = b.addStaticLibrary(.{
        .name = "ZDL3",
        .root_source_file = .{ .cwd_relative = "src/sdl3.zig" },
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

    // Unit tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/sdl3.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add SDL3 include paths for tests
    main_tests.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    main_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    main_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include/SDL3_ttf" });

    // Add SDL3 library paths for tests
    main_tests.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    main_tests.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    // Link SDL3 and SDL3_ttf for tests
    main_tests.linkSystemLibrary("SDL3");
    main_tests.linkSystemLibrary("SDL3_ttf");
    main_tests.linkLibC();

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
