const std = @import("std");
const zdl = @import("root.zig");
const c = zdl.c;

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
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    var window = try zdl.video.Window.create(
        "Test Window",
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    );
    defer window.destroy();

    // Test window operations
    try window.setSize(1024, 768);
    try window.setPosition(100, 100);
    try window.setTitle("Updated Title");

    // Create renderer
    var renderer = try zdl.render.Renderer.create(window, .{});
    defer renderer.destroy();

    // Set up frame timer
    var frame_timer = zdl.timer.FrameTimer.init(60);
    frame_timer.start();

    // Create a surface
    var surface1 = try zdl.surface.Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface1.destroy();

    // Fill surface with color
    try surface1.fill(zdl.pixels.Colors.red);

    // Main loop
    var running = true;
    var frame_count: u32 = 0;
    while (running and frame_count < 10) : (frame_count += 1) {
        // Process events
        while (zdl.events.pollEvent()) |event| {
            switch (event) {
                .quit => running = false,
                else => {},
            }
        }

        // Clear screen
        try renderer.setColor(zdl.pixels.Colors.black);
        try renderer.clear();

        // Draw something
        try renderer.setColor(zdl.pixels.Colors.red);
        try renderer.drawLine(0, 0, 100, 100);
        try renderer.fillRect(200, 200, 50, 50);
        try renderer.drawRect(300, 300, 50, 50);

        // Present frame
        try renderer.present();

        // Maintain frame rate
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
    try surface1.fill(zdl.pixels.Colors.red);

    // Draw a blue rectangle
    try surface1.fillRect(zdl.rect.Rect.init(10, 10, 80, 80), zdl.pixels.Colors.blue);

    // Create another surface and blit
    var surface2 = try zdl.surface.Surface.create(50, 50, c.SDL_PIXELFORMAT_RGBA32);
    defer surface2.destroy();

    // Fill with green
    try surface2.fill(zdl.pixels.Colors.green);
    try surface1.blit(surface2, zdl.rect.Rect.init(25, 25, 50, 50));

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
        c.SDL_WINDOW_RESIZABLE,
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
