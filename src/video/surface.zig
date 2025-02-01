const std = @import("std");
const c = @import("../c.zig");
const init = @import("../root.zig").init;
const PixelFormat = @import("pixels.zig").PixelFormat;

const testing = std.testing;
const video = @import("../video/module.zig");
const pixel_mod = video.pixels;
const rect = video.rect;

/// A handle to a surface
pub const Surface = struct {
    handle: *c.SDL_Surface,

    /// Create a new surface
    pub fn create(width: c_int, height: c_int, format: c_uint) !Surface {
        const handle = c.SDL_CreateSurface(width, height, format) orelse {
            return error.SDLError;
        };
        return Surface{ .handle = handle };
    }

    /// Load a surface from a file
    pub fn loadBMP(path: [:0]const u8) !Surface {
        const handle = c.SDL_LoadBMP(path) orelse return error.SDLError;
        return Surface{ .handle = handle };
    }

    /// Destroy a surface
    pub fn destroy(self: *Surface) void {
        c.SDL_DestroySurface(self.handle);
    }

    /// Get the surface's width
    pub fn getWidth(self: Surface) c_int {
        return self.handle.w;
    }

    /// Get the surface's height
    pub fn getHeight(self: Surface) c_int {
        return self.handle.h;
    }

    /// Get the surface's pixel format
    pub fn getFormat(self: Surface) c_uint {
        return @intCast(self.handle.format);
    }

    /// Lock a surface for direct access
    pub fn lock(self: Surface) !void {
        if (!c.SDL_LockSurface(self.handle)) {
            return error.SDLError;
        }
    }

    /// Unlock a previously locked surface
    pub fn unlock(self: Surface) void {
        c.SDL_UnlockSurface(self.handle);
    }

    /// Fill the surface with a color
    pub fn fill(self: Surface, color: pixel_mod.Color) !void {
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return error.SDLError;
        const pixel = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (c.SDL_FillSurfaceRect(self.handle, null, pixel)) {
            return error.SDLError;
        }
    }

    /// Fill a rectangle in the surface with a color
    pub fn fillRect(self: Surface, rect_: rect.Rect, color: pixel_mod.Color) !void {
        const sdl_rect = rect_.toSDL();
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return error.SDLError;
        const pixel = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (c.SDL_FillSurfaceRect(self.handle, &sdl_rect, pixel)) {
            return error.SDLError;
        }
    }

    /// Blit (copy) another surface onto this one
    pub fn blit(self: Surface, source: Surface, dst_rect: ?rect.Rect) !void {
        const sdl_rect = if (dst_rect) |r| r.toSDL() else null;
        if (c.SDL_BlitSurface(source.handle, null, self.handle, if (sdl_rect) |*r| r else null)) {
            return error.SDLError;
        }
    }

    /// Blit (copy) a portion of another surface onto this one
    pub fn blitRect(self: Surface, source: Surface, src_rect: rect.Rect, dst_rect: rect.Rect) !void {
        const sdl_src_rect = src_rect.toSDL();
        const sdl_dst_rect = dst_rect.toSDL();
        if (c.SDL_BlitSurface(source.handle, &sdl_src_rect, self.handle, &sdl_dst_rect)) {
            return error.SDLError;
        }
    }

    /// Save the surface to a BMP file
    pub fn saveBMP(self: Surface, path: [:0]const u8) !void {
        if (c.SDL_SaveBMP(self.handle, path)) {
            return error.SDLError;
        }
    }

    /// Get direct access to the pixel buffer
    pub fn pixels(self: Surface) [*]u8 {
        return @as([*]u8, @ptrCast(self.handle.pixels));
    }

    /// Set the color key (transparent pixel value)
    pub fn setColorKey(self: Surface, color: pixel_mod.Color) !void {
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return error.SDLError;
        const key = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (!c.SDL_SetSurfaceColorKey(self.handle, 1, key)) {
            return error.SDLError;
        }
    }

    /// Set the alpha modulation
    pub fn setAlphaMod(self: Surface, alpha: u8) !void {
        if (!c.SDL_SetSurfaceAlphaMod(self.handle, alpha)) {
            return error.SDLError;
        }
    }

    /// Set the color modulation
    pub fn setColorMod(self: Surface, color: pixel_mod.Color) !void {
        if (!c.SDL_SetSurfaceColorMod(self.handle, color.r, color.g, color.b)) {
            return error.SDLError;
        }
    }
};

test "surface operations" {
    const sdl = @import("../core/module.zig");
    try sdl.init(.{ .video = true });
    defer sdl.quit();

    var surface = try Surface.create(
        800,
        600,
        c.SDL_PIXELFORMAT_RGBA32,
    );
    defer surface.destroy();

    try surface.lock();
    defer surface.unlock();

    try std.testing.expectEqual(@as(c_int, 800), surface.getWidth());
    try std.testing.expectEqual(@as(c_int, 600), surface.getHeight());
    try std.testing.expectEqual(@as(c_uint, c.SDL_PIXELFORMAT_RGBA32), surface.getFormat());
}

test "surface format" {
    try init(.{ .video = true });
    defer @import("../root.zig").quit();

    var surface = try Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface.destroy();

    try std.testing.expectEqual(@as(c_uint, c.SDL_PIXELFORMAT_RGBA32), surface.getFormat());
}
