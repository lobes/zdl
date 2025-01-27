const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub const init = @import("init.zig");
pub const video = @import("video.zig");
pub const render = @import("render.zig");
pub const events = @import("events.zig");
pub const rect = @import("rect.zig");
pub const pixels = @import("pixels.zig");
pub const surface = @import("surface.zig");
pub const timer = @import("timer.zig");
pub const errors = @import("errors.zig");

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("SDL3 initialization failed: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow(
        "ZDL3 Window",
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        std.debug.print("Window creation failed: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    var running = true;
    while (running) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) == true) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => running = false,
                else => {},
            }
        }

        // Add a small delay to prevent maxing out CPU
        c.SDL_Delay(16); // roughly 60 FPS
    }
}

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
    try init.init(.{ .video = true });
    defer init.quit();

    // Create a window
    var window = try video.Window.create(
        "SDL3 Example",
        800,
        600,
        .{ .shown = true, .resizable = true },
    );
    defer window.destroy();

    // Create a renderer
    var renderer = try render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Create a frame timer for 60 FPS
    var frame_timer = timer.FrameTimer.init(60);
    frame_timer.start();

    // Main loop
    main_loop: while (true) {
        // Handle events
        while (events.pollEvent()) |event| {
            switch (event) {
                .quit => break :main_loop,
                .key_down => |key| {
                    if (key.keycode == .escape) break :main_loop;
                },
                else => {},
            }
        }

        // Clear screen
        renderer.setColor(pixels.Colors.black);
        renderer.clear();

        // Draw a rectangle
        renderer.setColor(pixels.Colors.red);
        renderer.fillRect(100, 100, 200, 200);

        // Draw a line
        renderer.setColor(pixels.Colors.green);
        renderer.drawLine(0, 0, 800, 600);

        // Present the frame
        renderer.present();

        // Maintain target frame rate
        frame_timer.update();
    }
}

// Example of how to use surfaces and pixel manipulation
test "surface manipulation" {
    try init.init(.{ .video = true });
    defer init.quit();

    // Create a surface
    var surface1 = try surface.Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface1.destroy();

    // Fill with red
    surface1.fill(pixels.Colors.red);

    // Draw a blue rectangle
    surface1.fillRect(rect.Rect.init(10, 10, 80, 80), pixels.Colors.blue);

    // Create another surface and blit
    var surface2 = try surface.Surface.create(50, 50, c.SDL_PIXELFORMAT_RGBA32);
    defer surface2.destroy();

    // Fill with green
    surface2.fill(pixels.Colors.green);

    // Blit surface2 onto surface1
    surface1.blit(surface2, rect.Rect.init(25, 25, 50, 50));

    // Save the result
    try surface1.saveBMP("test_surface.bmp");
}

// Example of how to handle input events
test "input handling" {
    try init.init(.{ .video = true });
    defer init.quit();

    var window = try video.Window.create(
        "Input Test",
        800,
        600,
        .{ .shown = true },
    );
    defer window.destroy();

    var mouse_pos = struct { x: i32 = 0, y: i32 = 0 }{};
    var keys_pressed = std.AutoHashMap(events.Keycode, void).init(std.testing.allocator);
    defer keys_pressed.deinit();

    var frame: u32 = 0;
    while (frame < 10) : (frame += 1) {
        while (events.pollEvent()) |event| {
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
        timer.delay(16); // ~60 FPS
    }
}
