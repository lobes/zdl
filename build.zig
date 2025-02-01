const std = @import("std");

const MIN_SDL_VERSION = .{
    .major = 3,
    .minor = 0,
    .patch = 0,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_include_path = switch (target.result.os.tag) {
        .macos => "/opt/homebrew/include",
        else => "/usr/local/include",
    };

    const default_lib_path = switch (target.result.os.tag) {
        .macos => "/opt/homebrew/lib",
        else => "/usr/local/lib",
    };

    const sdl_include_path = b.option(
        []const u8,
        "sdl-include-path",
        "Path to SDL include directory",
    ) orelse default_include_path;

    const sdl_lib_path = b.option(
        []const u8,
        "sdl-lib-path",
        "Path to SDL library directory",
    ) orelse default_lib_path;

    // Options following project structure
    const options = .{
        // Core module (always enabled)
        .enable_core = true,

        .enable_video = b.option(bool, "video", "Enable video module (windows, rendering)") orelse true,
        .enable_audio = b.option(bool, "audio", "Enable audio module") orelse true,
        .enable_graphics = b.option(bool, "graphics", "Enable graphics module") orelse true,
        .enable_input = b.option(bool, "input", "Enable input handling") orelse true,
        .enable_system = b.option(bool, "system", "Enable system functionality") orelse true,

        .enable_ttf = b.option(bool, "ttf", "Enable TTF font support") orelse false,
        .enable_mixer = b.option(bool, "mixer", "Enable audio mixing support") orelse false,

        .sdl_version = b.option(
            []const u8,
            "sdl-version",
            "Minimum SDL version required (e.g. '3.0.0')",
        ) orelse "3.0.0",

        // Runtime checks
        .runtime_safety = b.option(
            bool,
            "runtime-safety",
            "Enable runtime safety checks",
        ) orelse true,
    };

    const module_options = b.addOptions();
    inline for (@typeInfo(@TypeOf(options)).Struct.fields) |field| {
        module_options.addOption(field.type, field.name, @field(options, field.name));
    }

    const zdl_module = b.addModule("zdl", .{
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = module_options.createModule() },
        },
    });

    const lib = b.addStaticLibrary(.{
        .name = "zdl",
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const check_sdl_version = b.addSystemCommand(&.{
        "pkg-config",
        "--atleast-version=3.0.0",
        "sdl3",
    });
    lib.step.dependOn(&check_sdl_version.step);

    lib.addIncludePath(.{ .cwd_relative = sdl_include_path });
    lib.addLibraryPath(.{ .cwd_relative = sdl_lib_path });

    lib.linkSystemLibrary("SDL3");
    if (options.enable_ttf) lib.linkSystemLibrary("SDL3_ttf");
    if (options.enable_mixer) lib.linkSystemLibrary("SDL3_mixer");

    b.installArtifact(lib);

    // Unit tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Add build options to tests
    main_tests.root_module.addImport("build_options", module_options.createModule());

    main_tests.addIncludePath(.{ .cwd_relative = sdl_include_path });
    main_tests.addLibraryPath(.{ .cwd_relative = sdl_lib_path });

    main_tests.linkSystemLibrary("SDL3");
    if (options.enable_ttf) main_tests.linkSystemLibrary("SDL3_ttf");
    if (options.enable_mixer) main_tests.linkSystemLibrary("SDL3_mixer");
    main_tests.linkLibC();

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

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
    loldongs.addIncludePath(.{ .cwd_relative = sdl_include_path });
    loldongs.addLibraryPath(.{ .cwd_relative = sdl_lib_path });
    loldongs.linkSystemLibrary("SDL3");
    if (options.enable_ttf) loldongs.linkSystemLibrary("SDL3_ttf");
    if (options.enable_mixer) loldongs.linkSystemLibrary("SDL3_mixer");
    loldongs.linkLibC();

    const install_loldongs = b.addInstallArtifact(loldongs, .{});
    examples_step.dependOn(&install_loldongs.step);
}
