const std = @import("std");
const zdl = @import("root.zig");
const c = zdl.c;

const init = @import("core/init.zig");
const video = @import("video/module.zig");
const render = @import("video/render.zig");
const events = @import("core/events.zig");
const rect = @import("video/rect.zig");
const pixels = @import("video/pixels.zig");
const surface = @import("video/surface.zig");
const timer = @import("core/timer.zig");
const errors = @import("core/error.zig");

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit();
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test {
    // Test all modules
    std.testing.refAllDecls(@This());
}

// Example of how to use the SDL3 wrapper
test "basic usage" {
    // Initialize SDL with video subsystem
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    // Create a window
    var window = try zdl.video.Window.create(
        "SDL3 Example",
        800,
        600,
        .{ .shown = true, .resizable = true },
    );
    defer window.destroy();

    // Create a renderer
    var renderer = try zdl.render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Create a frame timer for 60 FPS
    var frame_timer = zdl.timer.FrameTimer.init(60);
    frame_timer.start();

    // Main loop
    main_loop: while (true) {
        // Handle events
        while (zdl.events.pollEvent()) |event| {
            switch (event) {
                .quit => break :main_loop,
                .key_down => |key| {
                    if (key.keycode == .escape) break :main_loop;
                },
                else => {},
            }
        }

        // Clear screen
        renderer.setColor(zdl.pixels.Colors.black);
        renderer.clear();

        // Draw a rectangle
        renderer.setColor(zdl.pixels.Colors.red);
        renderer.fillRect(100, 100, 200, 200);

        // Draw a line
        renderer.setColor(zdl.pixels.Colors.green);
        renderer.drawLine(0, 0, 800, 600);

        // Present the frame
        renderer.present();

        // Maintain target frame rate
        frame_timer.update();
    }
}

// Example of how to use surfaces and pixel manipulation
test "surface manipulation" {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    // Create a surface
    var surface1 = try zdl.surface.Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface1.destroy();

    // Fill with red
    surface1.fill(zdl.pixels.Colors.red);

    // Draw a blue rectangle
    surface1.fillRect(zdl.rect.Rect.init(10, 10, 80, 80), zdl.pixels.Colors.blue);

    // Create another surface and blit
    var surface2 = try zdl.surface.Surface.create(50, 50, c.SDL_PIXELFORMAT_RGBA32);
    defer surface2.destroy();

    // Fill with green
    surface2.fill(zdl.pixels.Colors.green);

    // Blit surface2 onto surface1
    surface1.blit(surface2, zdl.rect.Rect.init(25, 25, 50, 50));

    // Save the result
    try surface1.saveBMP("test_surface.bmp");
}

// Example of how to handle input events
test "input handling" {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    var window = try zdl.video.Window.create(
        "Input Test",
        800,
        600,
        .{ .shown = true },
    );
    defer window.destroy();

    var mouse_pos = struct { x: i32 = 0, y: i32 = 0 }{};
    var keys_pressed = std.AutoHashMap(zdl.events.Keycode, void).init(std.testing.allocator);
    defer keys_pressed.deinit();

    var frame: u32 = 0;
    while (frame < 10) : (frame += 1) {
        while (zdl.events.pollEvent()) |event| {
            switch (event) {
                .quit => break,
                .key_down => |key| {
                    try keys_pressed.put(key.keycode, {});
                },
                .key_up => |key| {
                    _ = keys_pressed.remove(key.keycode);
                },
                .mouse_motion => |motion| {
                    mouse_pos.x = @intFromFloat(motion.x);
                    mouse_pos.y = @intFromFloat(motion.y);
                },
                else => {},
            }
        }
        zdl.timer.delay(16); // ~60 FPS
    }
}
