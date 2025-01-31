const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Export the module
    const zdl_module = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .imports = &.{},
    });
    b.modules.put("zdl", zdl_module) catch unreachable;

    // Static library
    const lib = b.addStaticLibrary(.{
        .name = "zdl",
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Common paths to search for SDL3
    const search_paths = [_][]const u8{
        "/usr/local/include",
        "/usr/local/include/SDL3",
        "/usr/local/lib",
        "~/.local/include",
        "~/.local/lib",
        "~/things/SDL/include",
        "~/things/SDL/build",
    };

    // Add include paths
    inline for (search_paths) |path| {
        lib.addIncludePath(.{ .cwd_relative = path });
    }

    // Link against SDL3 and extensions
    lib.linkSystemLibrary("SDL3");
    lib.linkSystemLibrary("SDL3_ttf");
    lib.linkSystemLibrary("SDL3_mixer");
    lib.linkLibC();

    b.installArtifact(lib);

    // Unit tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add the same paths and libraries to tests
    inline for (search_paths) |path| {
        main_tests.addIncludePath(.{ .cwd_relative = path });
    }

    main_tests.linkSystemLibrary("SDL3");
    main_tests.linkSystemLibrary("SDL3_ttf");
    main_tests.linkSystemLibrary("SDL3_mixer");
    main_tests.linkLibC();

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // #todo
    // // Add examples
    // const examples_step = b.step("examples", "Build examples");

    // // // Example: Basic window
    // // const basic_example = b.addExecutable(.{
    // //     .name = "basic",
    // //     .root_source_file = .{ .cwd_relative = "examples/basic.zig" },
    // //     .target = target,
    // //     .optimize = optimize,
    // // });
    // // basic_example.addModule("zdl", zdl_module);
    // // basic_example.linkLibrary(lib);
    // // examples_step.dependOn(&b.addInstallArtifact(basic_example).step);
}
