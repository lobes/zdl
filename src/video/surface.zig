const std = @import("std");
const zdl = @import("../../zdl.zig");
const c = zdl.c;
const init = zdl.init;
const PixelFormat = @import("pixels.zig").PixelFormat;

const testing = std.testing;
const video = @import("../video/module.zig");
const pixel_mod = video.pixels;
const rect = video.rect;

/// A handle to a surface
pub const Surface = struct {
    handle: *c.SDL_Surface,

    /// Create a new surface
    pub fn create(width: u32, height: u32, format: u32) !Surface {
        const handle = c.SDL_CreateSurface(
            @intCast(width),
            @intCast(height),
            format,
        ) orelse return error.TextureCreationFailed;
        return Surface{ .handle = handle };
    }

    /// Load a surface from a file
    pub fn loadBMP(path: [:0]const u8) !Surface {
        const handle = c.SDL_LoadBMP(path) orelse return error.FileNotFound;
        return Surface{ .handle = handle };
    }

    /// Destroy a surface
    pub fn destroy(self: *Surface) void {
        c.SDL_DestroySurface(self.handle);
    }

    /// Get the surface's width
    pub fn getWidth(self: Surface) i32 {
        return self.handle.w;
    }

    /// Get the surface's height
    pub fn getHeight(self: Surface) i32 {
        return self.handle.h;
    }

    /// Get the surface's pixel format
    pub fn getFormat(self: Surface) u32 {
        return @intCast(self.handle.format);
    }

    /// Lock a surface for direct access
    pub fn lock(self: Surface) !void {
        if (!c.SDL_LockSurface(self.handle)) {
            return error.InvalidTexture;
        }
    }

    /// Unlock a previously locked surface
    pub fn unlock(self: Surface) void {
        c.SDL_UnlockSurface(self.handle);
    }

    /// Fill the surface with a color
    pub fn fill(self: Surface, color: zdl.pixels.Color) !void {
        if (!c.SDL_FillSurfaceRect(self.handle, null, color.toSDL())) {
            return error.InvalidTexture;
        }
    }

    /// Fill a rectangle in the surface with a color
    pub fn fillRect(self: Surface, rect_area: zdl.rect.Rect, color: zdl.pixels.Color) !void {
        const sdl_rect = rect_area.toSDL();
        if (!c.SDL_FillSurfaceRect(self.handle, &sdl_rect, color.toSDL())) {
            return error.InvalidTexture;
        }
    }

    /// Blit (copy) another surface onto this one
    pub fn blit(self: Surface, src: Surface, dst_rect: zdl.rect.Rect) !void {
        const sdl_rect = dst_rect.toSDL();
        if (!c.SDL_BlitSurface(src.handle, null, self.handle, &sdl_rect)) {
            return error.InvalidTexture;
        }
    }

    /// Blit (copy) a portion of another surface onto this one
    pub fn blitRect(self: Surface, source: Surface, src_rect: zdl.rect.Rect, dst_rect: zdl.rect.Rect) !void {
        const sdl_src_rect = src_rect.toSDL();
        const sdl_dst_rect = dst_rect.toSDL();
        if (!c.SDL_BlitSurface(source.handle, &sdl_src_rect, self.handle, &sdl_dst_rect)) {
            return error.InvalidTexture;
        }
    }

    /// Save the surface to a BMP file
    pub fn saveBMP(self: Surface, file: [:0]const u8) !void {
        if (!c.SDL_SaveBMP(self.handle, file.ptr)) {
            return error.FileIOError;
        }
    }

    /// Get direct access to the pixel buffer
    pub fn pixels(self: Surface) [*]u8 {
        return @as([*]u8, @ptrCast(self.handle.pixels));
    }

    /// Set the color key (transparent pixel value)
    pub fn setColorKey(self: Surface, color: zdl.pixels.Color) !void {
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return error.InvalidTexture;
        const key = c.SDL_MapRGBA(format, color.r, color.g, color.b, color.a);
        if (!c.SDL_SetSurfaceColorKey(self.handle, 1, key)) {
            return error.InvalidTexture;
        }
    }

    /// Set the alpha modulation
    pub fn setAlphaMod(self: Surface, alpha: u8) !void {
        if (!c.SDL_SetSurfaceAlphaMod(self.handle, alpha)) {
            return error.InvalidTexture;
        }
    }

    /// Set the color modulation
    pub fn setColorMod(self: Surface, color: zdl.pixels.Color) !void {
        if (!c.SDL_SetSurfaceColorMod(self.handle, color.r, color.g, color.b)) {
            return error.InvalidTexture;
        }
    }
};

test "surface operations" {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    var surface = try Surface.create(
        800,
        600,
        c.SDL_PIXELFORMAT_RGBA32,
    );
    defer surface.destroy();

    try surface.lock();
    defer surface.unlock();

    try std.testing.expectEqual(@as(i32, 800), surface.getWidth());
    try std.testing.expectEqual(@as(i32, 600), surface.getHeight());
    try std.testing.expectEqual(@as(u32, c.SDL_PIXELFORMAT_RGBA32), surface.getFormat());
}

test "surface format" {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    var surface = try Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface.destroy();

    try std.testing.expectEqual(@as(u32, c.SDL_PIXELFORMAT_RGBA32), surface.getFormat());
}
