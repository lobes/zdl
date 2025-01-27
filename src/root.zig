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

pub fn main() !void {
    // Initialize SDL with video subsystem
    try init.init(.{ .video = true });
    defer init.quit();

    // Initialize TTF
    try ttf.Font.init();
    defer ttf.Font.quit();

    // Create a fullscreen window
    var window = try video.Window.create(
        "loldongs",
        800,
        600,
        .{ .fullscreen = true },
    );
    defer window.destroy();

    // Create a renderer
    var renderer = try render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Load font
    var font = try ttf.Font.load("/System/Library/Fonts/Helvetica.ttc", 72);
    defer font.close();

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
            .x = @as(f32, @floatFromInt(800)) / 2.0 - text_width / 2.0,
            .y = @as(f32, @floatFromInt(600)) / 2.0 - text_height / 2.0,
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
