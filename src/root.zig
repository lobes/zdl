const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const std = @import("std");
const testing = std.testing;

pub const init = @import("init.zig");
pub const video = @import("video.zig");
pub const render = @import("render.zig");
pub const events = @import("events.zig");
pub const rect = @import("rect.zig");
pub const pixels = @import("pixels.zig");
pub const surface = @import("surface.zig");
pub const timer = @import("timer.zig");
pub const errors = @import("errors.zig");
pub const ttf = @import("ttf.zig");

const MonitorInfo = struct {
    display_id: i32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

fn runLoldongs(monitor: MonitorInfo) !void {
    std.debug.print("Initializing SDL for monitor {d}\n", .{monitor.display_id});

    // Initialize SDL with video subsystem
    try init.init(.{ .video = true });
    defer init.quit();

    // Initialize TTF
    try ttf.Font.init();
    defer ttf.Font.quit();

    std.debug.print("Creating window at ({d}, {d}) {d}x{d}\n", .{ monitor.x, monitor.y, monitor.width, monitor.height });

    // Create a window on the specified display
    var window = try video.Window.create(
        "loldongs",
        monitor.width,
        monitor.height,
        .{
            .fullscreen = true,
            .x = monitor.x,
            .y = monitor.y,
            .display_id = @as(u32, @intCast(monitor.display_id)),
        },
    );
    defer window.destroy();

    // Set window position
    window.setPosition(monitor.x, monitor.y);

    std.debug.print("Creating renderer\n", .{});

    // Create a renderer
    var renderer = try render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Load font
    var font = try ttf.Font.load("/System/Library/Fonts/Helvetica.ttc", 72);
    defer font.close();

    std.debug.print("Entering main loop\n", .{});

    // Main loop
    var running = true;
    while (running) {
        // Handle events
        while (events.pollEvent()) |event| {
            switch (event) {
                .quit => running = false,
                .key_down => |key| {
                    if (key.keycode == .escape) running = false;
                },
                else => {},
            }
        }

        // Clear screen
        try renderer.setColor(pixels.Colors.black);
        try renderer.clear();

        // Render text
        const text_surface = try font.renderBlended("LOLDONGS", pixels.Colors.white);
        defer c.SDL_DestroySurface(text_surface);

        // Create texture from surface
        const text_texture = c.SDL_CreateTextureFromSurface(@ptrCast(renderer.handle), text_surface) orelse return errors.SDLError.TextureCreationFailed;
        defer c.SDL_DestroyTexture(text_texture);

        // Get texture dimensions
        var text_width: f32 = undefined;
        var text_height: f32 = undefined;
        if (!c.SDL_GetTextureSize(text_texture, &text_width, &text_height)) {
            return errors.SDLError.TextureQueryFailed;
        }

        // Center text
        const dest_rect = c.SDL_FRect{
            .x = @as(f32, @floatFromInt(monitor.width)) / 2.0 - text_width / 2.0,
            .y = @as(f32, @floatFromInt(monitor.height)) / 2.0 - text_height / 2.0,
            .w = text_width,
            .h = text_height,
        };

        // Draw text
        _ = c.SDL_RenderTexture(@ptrCast(renderer.handle), text_texture, null, &dest_rect);

        // Present
        try renderer.present();

        // Small delay to prevent maxing out CPU
        timer.delay(16); // roughly 60 FPS
    }

    std.debug.print("Child process exiting normally\n", .{});
}

pub fn main() !void {
    // Get command line args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    std.debug.print("Starting with args: {s}\n", .{args});

    // Check if we're a child process
    if (args.len > 1 and std.mem.eql(u8, args[1], "--monitor")) {
        std.debug.print("Child process starting for monitor\n", .{});
        // Parse monitor info from args
        const monitor = MonitorInfo{
            .display_id = try std.fmt.parseInt(i32, args[2], 10),
            .x = try std.fmt.parseInt(i32, args[3], 10),
            .y = try std.fmt.parseInt(i32, args[4], 10),
            .width = try std.fmt.parseInt(i32, args[5], 10),
            .height = try std.fmt.parseInt(i32, args[6], 10),
        };
        try runLoldongs(monitor);
        return;
    }

    std.debug.print("Parent process starting\n", .{});

    // Parent process - spawn children for each monitor
    try init.init(.{ .video = true });
    defer init.quit();

    // Get displays
    var num_displays: i32 = undefined;
    const displays = c.SDL_GetDisplays(&num_displays) orelse return errors.SDLError.InitializationFailed;
    if (num_displays <= 0) {
        return errors.SDLError.InitializationFailed;
    }

    std.debug.print("Found {d} displays\n", .{num_displays});

    // For each display
    var i: usize = 0;
    var processes = std.ArrayList(std.process.Child).init(std.heap.page_allocator);
    defer processes.deinit();

    while (i < @as(usize, @intCast(num_displays))) : (i += 1) {
        const display_id = displays[i];

        // Get display bounds
        var bounds: c.SDL_Rect = undefined;
        if (!c.SDL_GetDisplayBounds(display_id, &bounds)) {
            continue;
        }

        std.debug.print("Spawning child for display {d} at ({d}, {d}) {d}x{d}\n", .{ i, bounds.x, bounds.y, bounds.w, bounds.h });

        // Create child process
        const exe_path = try std.fs.selfExePathAlloc(std.heap.page_allocator);
        const child_args = [_][]const u8{
            exe_path,
            "--monitor",
            try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{i}),
            try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{bounds.x}),
            try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{bounds.y}),
            try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{bounds.w}),
            try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{bounds.h}),
        };

        var child = std.process.Child.init(&child_args, std.heap.page_allocator);
        child.stdin_behavior = .Close;
        child.stdout_behavior = .Close;
        child.stderr_behavior = .Inherit;

        try child.spawn();
        try processes.append(child);
    }

    std.debug.print("Waiting for {d} child processes\n", .{processes.items.len});

    // Wait for all child processes
    for (processes.items) |*child| {
        const term = try child.wait();
        std.debug.print("Child process exited with term: {}\n", .{term});
    }
}

test {
    _ = init;
    _ = video;
    _ = render;
    _ = events;
    _ = rect;
    _ = pixels;
    _ = surface;
    _ = timer;
    _ = errors;
    _ = ttf;
    testing.refAllDecls(@This());
}
