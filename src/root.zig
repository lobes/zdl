const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_mixer/SDL_mixer.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const std = @import("std");
const testing = std.testing;

pub const init = @import("core/init.zig");
pub const video = @import("video/module.zig");
pub const render = @import("video/render.zig");
pub const events = @import("core/events.zig");
pub const rect = @import("video/rect.zig");
pub const pixels = @import("video/pixels.zig");
pub const surface = @import("video/surface.zig");
pub const timer = @import("core/timer.zig");
pub const errors = @import("core/error.zig");
pub const ttf = @import("ttf/ttf.zig");

const MonitorInfo = struct {
    display_id: i32,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

const TextInput = struct {
    text: [256]u8 = [_]u8{' '} ** 256,
    length: usize = 1,
    active: bool = false,
    window: *video.Window,

    pub fn init(window: *video.Window) TextInput {
        var result = TextInput{
            .window = window,
        };
        result.text[0] = ' ';
        result.text[1] = 0;
        result.length = 1;
        return result;
    }

    pub fn activate(self: *TextInput) void {
        self.active = true;
        _ = c.SDL_StartTextInput(@ptrCast(self.window.handle));
    }

    pub fn deactivate(self: *TextInput) void {
        self.active = false;
        _ = c.SDL_StopTextInput(@ptrCast(self.window.handle));
    }

    pub fn handleEvent(self: *TextInput, event: events.Event) void {
        switch (event) {
            .text_input => |text_event| {
                if (self.active and self.length < 255) {
                    // Copy new text ensuring we don't overflow
                    var i: usize = 0;
                    while (i < text_event.text.len and text_event.text[i] != 0 and self.length < 255) : (i += 1) {
                        self.text[self.length] = text_event.text[i];
                        self.length += 1;
                    }
                    self.text[self.length] = 0;
                }
            },
            .key_down => |key| {
                if (self.active) {
                    if (key.keycode == .backspace and self.length > 0) {
                        self.length -= 1;
                        self.text[self.length] = 0;
                    }
                }
            },
            else => {},
        }
    }
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
        "Text Input Demo",
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

    // Create text input
    var text_input = TextInput.init(&window);
    text_input.activate();

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
            text_input.handleEvent(event);
        }

        // Clear screen
        try renderer.setColor(pixels.Colors.black);
        try renderer.clear();

        // Render label
        const label_surface = try font.renderBlended("Input: ", pixels.Colors.white);
        defer c.SDL_DestroySurface(label_surface);
        const label_texture = c.SDL_CreateTextureFromSurface(@ptrCast(renderer.handle), label_surface) orelse return errors.SDLError.TextureCreationFailed;
        defer c.SDL_DestroyTexture(label_texture);

        // Render input text
        const input_text = text_input.text[0..text_input.length];
        const input_surface = try font.renderBlended(input_text, pixels.Colors.white);
        defer c.SDL_DestroySurface(input_surface);
        const input_texture = c.SDL_CreateTextureFromSurface(@ptrCast(renderer.handle), input_surface) orelse return errors.SDLError.TextureCreationFailed;
        defer c.SDL_DestroyTexture(input_texture);

        // Get texture dimensions
        var label_width: f32 = undefined;
        var label_height: f32 = undefined;
        var input_width: f32 = undefined;
        var input_height: f32 = undefined;

        if (!c.SDL_GetTextureSize(label_texture, &label_width, &label_height)) {
            return errors.SDLError.TextureQueryFailed;
        }
        if (!c.SDL_GetTextureSize(input_texture, &input_width, &input_height)) {
            return errors.SDLError.TextureQueryFailed;
        }

        // Center everything vertically, but align horizontally
        const center_y = @as(f32, @floatFromInt(monitor.height)) / 2.0 - label_height / 2.0;
        const start_x = @as(f32, @floatFromInt(monitor.width)) / 2.0 - (label_width + input_width + 10) / 2.0;

        // Draw label
        const label_rect = c.SDL_FRect{
            .x = start_x,
            .y = center_y,
            .w = label_width,
            .h = label_height,
        };
        _ = c.SDL_RenderTexture(@ptrCast(renderer.handle), label_texture, null, &label_rect);

        // Draw input text
        const input_rect = c.SDL_FRect{
            .x = start_x + label_width + 10,
            .y = center_y,
            .w = input_width,
            .h = input_height,
        };
        _ = c.SDL_RenderTexture(@ptrCast(renderer.handle), input_texture, null, &input_rect);

        // Draw cursor if active
        if (text_input.active) {
            const cursor_rect = c.SDL_FRect{
                .x = input_rect.x + input_width + 2,
                .y = input_rect.y,
                .w = 2,
                .h = input_height,
            };
            try renderer.setColor(pixels.Colors.white);
            _ = c.SDL_RenderFillRect(@ptrCast(renderer.handle), &cursor_rect);
        }

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

test "TextInput initialization" {
    // Initialize SDL for testing
    try init.init(.{ .video = true });
    defer init.quit();

    // Create a test window
    var window = try video.Window.create(
        "Test Window",
        800,
        600,
        .{ .shown = true },
    );
    defer window.destroy();

    // Test basic initialization
    const text_input = TextInput.init(&window);
    try testing.expectEqual(@as(usize, 1), text_input.length);
    try testing.expectEqual(@as(u8, ' '), text_input.text[0]);
    try testing.expectEqual(@as(u8, 0), text_input.text[1]);
    try testing.expect(!text_input.active);
}

test "TextInput text handling" {
    // Initialize SDL for testing
    try init.init(.{ .video = true });
    defer init.quit();

    // Create a test window
    var window = try video.Window.create(
        "Test Window",
        800,
        600,
        .{ .shown = true },
    );
    defer window.destroy();

    // Create text input
    var text_input = TextInput.init(&window);

    // Test text input event
    const text_event = events.Event{
        .text_input = .{
            .text = [_]u8{ 'h', 'i', 0 } ++ [_]u8{0} ** 29,
        },
    };
    text_input.handleEvent(text_event);

    // Should not handle text when inactive
    try testing.expectEqual(@as(usize, 1), text_input.length);
    try testing.expectEqual(@as(u8, ' '), text_input.text[0]);

    // Activate and try again
    text_input.activate();
    try testing.expect(text_input.active);
    text_input.handleEvent(text_event);

    // Should now have "hi" appended
    try testing.expectEqual(@as(usize, 3), text_input.length);
    try testing.expectEqual(@as(u8, ' '), text_input.text[0]);
    try testing.expectEqual(@as(u8, 'h'), text_input.text[1]);
    try testing.expectEqual(@as(u8, 'i'), text_input.text[2]);
    try testing.expectEqual(@as(u8, 0), text_input.text[3]);

    // Test backspace
    const backspace_event = events.Event{
        .key_down = .{
            .scancode = .unknown,
            .keycode = .backspace,
            .mod = .{},
            .repeat = false,
        },
    };
    text_input.handleEvent(backspace_event);

    // Should have removed last character
    try testing.expectEqual(@as(usize, 2), text_input.length);
    try testing.expectEqual(@as(u8, ' '), text_input.text[0]);
    try testing.expectEqual(@as(u8, 'h'), text_input.text[1]);
    try testing.expectEqual(@as(u8, 0), text_input.text[2]);

    // Test deactivation
    text_input.deactivate();
    try testing.expect(!text_input.active);

    // Should not handle input when deactivated
    text_input.handleEvent(text_event);
    try testing.expectEqual(@as(usize, 2), text_input.length);
}

test "TextInput buffer overflow protection" {
    // Initialize SDL for testing
    try init.init(.{ .video = true });
    defer init.quit();

    // Create a test window
    var window = try video.Window.create(
        "Test Window",
        800,
        600,
        .{ .shown = true },
    );
    defer window.destroy();

    // Create text input
    var text_input = TextInput.init(&window);
    text_input.activate();

    // Create a very long text event
    const long_text = [_]u8{'a'} ** 32;
    const text_event = events.Event{
        .text_input = .{
            .text = long_text,
        },
    };

    // Try to fill the buffer multiple times
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        text_input.handleEvent(text_event);
    }

    // Verify we haven't exceeded buffer size
    try testing.expect(text_input.length <= 255);
    try testing.expectEqual(@as(u8, 0), text_input.text[text_input.length]);
}
