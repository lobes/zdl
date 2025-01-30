const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");
const core = @import("../core/module.zig");
const errors = core.errors;
const video = @import("../video/module.zig");
const pixels = video.pixels;
const rect = video.rect;

pub const Renderer = struct {
    handle: *c.SDL_Renderer,

    pub const CreateFlags = struct {
        software: bool = false,
        accelerated: bool = true,
        vsync: bool = false,
        target_texture: bool = false,

        pub fn toSDLFlags(self: CreateFlags) u32 {
            var flags: u32 = 0;
            if (self.software) flags |= c.SDL_RENDERER_SOFTWARE;
            if (self.accelerated) flags |= c.SDL_RENDERER_ACCELERATED;
            if (self.vsync) flags |= c.SDL_RENDERER_PRESENTVSYNC;
            if (self.target_texture) flags |= c.SDL_RENDERER_TARGETTEXTURE;
            return flags;
        }
    };

    /// Create a new renderer for a window
    pub fn create(window: video.Window, _: CreateFlags) !Renderer {
        const handle = c.SDL_CreateRenderer(
            window.handle,
            null,
        ) orelse return errors.SDLError.RendererCreationFailed;

        return Renderer{ .handle = handle };
    }

    /// Destroy the renderer
    pub fn destroy(self: *Renderer) void {
        c.SDL_DestroyRenderer(self.handle);
    }

    /// Clear the current rendering target with the drawing color
    pub fn clear(self: Renderer) !void {
        if (!c.SDL_RenderClear(self.handle)) {
            return error.RenderClearFailed;
        }
    }

    /// Update the screen with any rendering performed since the previous call
    pub fn present(self: Renderer) !void {
        if (!c.SDL_RenderPresent(self.handle)) {
            return error.RenderPresentFailed;
        }
    }

    /// Set the color used for drawing operations
    pub fn setColor(self: Renderer, color: pixels.Color) !void {
        if (!c.SDL_SetRenderDrawColor(self.handle, color.r, color.g, color.b, color.a)) {
            return error.SetColorFailed;
        }
    }

    /// Draw a line between two points
    pub fn drawLine(self: Renderer, x1: f32, y1: f32, x2: f32, y2: f32) !void {
        if (!c.SDL_RenderLine(self.handle, x1, y1, x2, y2)) {
            return error.DrawLineFailed;
        }
    }

    /// Draw a filled rectangle
    pub fn fillRect(self: Renderer, x: f32, y: f32, w: f32, h: f32) !void {
        const fill_rect = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = h };
        if (!c.SDL_RenderFillRect(self.handle, &fill_rect)) {
            return error.FillRectFailed;
        }
    }

    /// Draw a rectangle outline
    pub fn drawRect(self: Renderer, x: f32, y: f32, w: f32, h: f32) !void {
        const draw_rect = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = h };
        if (!c.SDL_RenderRect(self.handle, &draw_rect)) {
            return error.DrawRectFailed;
        }
    }

    /// Draw debug text at the given position
    pub fn renderText(self: Renderer, x: f32, y: f32, text: []const u8) !void {
        if (!c.SDL_RenderDebugText(self.handle, x, y, text.ptr)) {
            return error.RenderTextFailed;
        }
    }
};

test "basic rendering" {
    try core.init.init(.{ .video = true });
    defer core.init.quit();

    var window = try video.Window.create("Test", 800, 600, .{});
    defer window.destroy();

    var renderer = try Renderer.create(window, .{});
    defer renderer.destroy();

    try renderer.setColor(pixels.Colors.red);
    try renderer.clear();
    try renderer.present();
}
