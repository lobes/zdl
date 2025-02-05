const std = @import("std");

const MIN_SDL_VERSION = .{
    .major = 3,
    .minor = 0,
    .patch = 0,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run all tests in all modes.");
    const tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "zdl.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);

    const docs_step = b.step("docs", "Generate docs.");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);

    // Options following project structure
    const enable_ttf = b.option(bool, "ttf", "Enable TTF font support") orelse false;
    const enable_mixer = b.option(bool, "mixer", "Enable audio mixing support") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "enable_core", true);
    options.addOption(bool, "enable_video", b.option(bool, "video", "Enable video module (windows, rendering)") orelse true);
    options.addOption(bool, "enable_audio", b.option(bool, "audio", "Enable audio module") orelse true);
    options.addOption(bool, "enable_graphics", b.option(bool, "graphics", "Enable graphics module") orelse true);
    options.addOption(bool, "enable_input", b.option(bool, "input", "Enable input handling") orelse true);
    options.addOption(bool, "enable_system", b.option(bool, "system", "Enable system functionality") orelse true);
    options.addOption(bool, "enable_ttf", enable_ttf);
    options.addOption(bool, "enable_mixer", enable_mixer);
    options.addOption([]const u8, "sdl_version", "3.0.0");
    options.addOption(bool, "runtime_safety", true);

    // Create and expose the root module
    const zdl_module = b.addModule("zdl", .{
        .root_source_file = .{ .cwd_relative = "zdl.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = options.createModule() },
        },
    });

    const lib = b.addStaticLibrary(.{
        .name = "zdl",
        .root_source_file = .{ .cwd_relative = "zdl.zig" },
        .target = target,
        .optimize = optimize,
    });

    const check_sdl_version = b.addSystemCommand(&.{
        "pkg-config",
        "--atleast-version=3.0.0",
        "sdl3",
    });
    lib.step.dependOn(&check_sdl_version.step);

    lib.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    lib.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    lib.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    lib.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });

    lib.linkSystemLibrary("SDL3");
    if (enable_ttf) lib.linkSystemLibrary("SDL3_ttf");
    if (enable_mixer) lib.linkSystemLibrary("SDL3_mixer");
    lib.linkLibC();

    b.installArtifact(lib);

    // Unit tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "zdl.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add build options to tests
    main_tests.root_module.addImport("build_options", options.createModule());

    main_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    main_tests.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });

    main_tests.linkSystemLibrary("SDL3");
    if (enable_ttf) main_tests.linkSystemLibrary("SDL3_ttf");
    if (enable_mixer) main_tests.linkSystemLibrary("SDL3_mixer");
    main_tests.linkLibC();

    // Examples
    const examples_step = b.step("examples", "Build examples");

    // Example: loldongs
    const loldongs = b.addExecutable(.{
        .name = "loldongs",
        .root_source_file = .{ .cwd_relative = "examples/loldongs.zig" },
        .target = target,
        .optimize = optimize,
    });

    loldongs.root_module.addImport("zdl", zdl_module);
    loldongs.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    loldongs.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    loldongs.linkSystemLibrary("SDL3");
    if (enable_ttf) loldongs.linkSystemLibrary("SDL3_ttf");
    if (enable_mixer) loldongs.linkSystemLibrary("SDL3_mixer");
    loldongs.linkLibC();

    const install_loldongs = b.addInstallArtifact(loldongs, .{});
    examples_step.dependOn(&install_loldongs.step);
}
