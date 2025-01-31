const std = @import("std");
const zdl = @import("zdl");
const c = zdl.c;

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
    window: *zdl.video.Window,

    pub fn init(window: *zdl.video.Window) TextInput {
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

    pub fn handleEvent(self: *TextInput, event: zdl.events.Event) void {
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
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    // Initialize TTF
    try zdl.ttf.Font.init();
    defer zdl.ttf.Font.quit();

    std.debug.print("Creating window at ({d}, {d}) {d}x{d}\n", .{ monitor.x, monitor.y, monitor.width, monitor.height });

    // Create a window on the specified display
    var window = try zdl.video.Window.create(
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
    var renderer = try zdl.render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Load font
    var font = try zdl.ttf.Font.load("/System/Library/Fonts/Helvetica.ttc", 72);
    defer font.close();

    // Create text input
    var text_input = TextInput.init(&window);
    text_input.activate();

    std.debug.print("Entering main loop\n", .{});

    // Main loop
    var running = true;
    while (running) {
        // Handle events
        while (zdl.events.pollEvent()) |event| {
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
        try renderer.setColor(zdl.pixels.Colors.black);
        try renderer.clear();

        // Render label
        const label_surface = try font.renderBlended("Input: ", zdl.pixels.Colors.white);
        defer c.SDL_DestroySurface(label_surface);
        const label_texture = c.SDL_CreateTextureFromSurface(@ptrCast(renderer.handle), label_surface) orelse return zdl.errors.SDLError.TextureCreationFailed;
        defer c.SDL_DestroyTexture(label_texture);

        // Render input text
        const input_text = text_input.text[0..text_input.length];
        const input_surface = try font.renderBlended(input_text, zdl.pixels.Colors.white);
        defer c.SDL_DestroySurface(input_surface);
        const input_texture = c.SDL_CreateTextureFromSurface(@ptrCast(renderer.handle), input_surface) orelse return zdl.errors.SDLError.TextureCreationFailed;
        defer c.SDL_DestroyTexture(input_texture);

        // Get texture dimensions
        var label_width: f32 = undefined;
        var label_height: f32 = undefined;
        var input_width: f32 = undefined;
        var input_height: f32 = undefined;

        if (!c.SDL_GetTextureSize(label_texture, &label_width, &label_height)) {
            return zdl.errors.SDLError.TextureQueryFailed;
        }
        if (!c.SDL_GetTextureSize(input_texture, &input_width, &input_height)) {
            return zdl.errors.SDLError.TextureQueryFailed;
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
            try renderer.setColor(zdl.pixels.Colors.white);
            _ = c.SDL_RenderFillRect(@ptrCast(renderer.handle), &cursor_rect);
        }

        // Present
        try renderer.present();

        // Small delay to prevent maxing out CPU
        zdl.timer.delay(16); // roughly 60 FPS
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
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    // Get displays
    var num_displays: i32 = undefined;
    const displays = c.SDL_GetDisplays(&num_displays) orelse return zdl.errors.SDLError.InitializationFailed;
    if (num_displays <= 0) {
        return zdl.errors.SDLError.InitializationFailed;
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
