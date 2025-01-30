const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const testing = @import("std").testing;
const core = @import("../core/module.zig");
const errors = core.errors;
const video = @import("../video/module.zig");
const pixel_mod = video.pixels;
const rect = video.rect;

pub const Surface = struct {
    handle: *c.SDL_Surface,

    /// Create a new RGB surface
    pub fn create(w: i32, h: i32, pixel_format: u32) !Surface {
        _ = c.SDL_GetPixelFormatDetails(pixel_format) orelse return errors.SDLError.PixelFormatError;
        const handle = c.SDL_CreateSurface(
            @as(c_int, @intCast(w)),
            @as(c_int, @intCast(h)),
            pixel_format,
        ) orelse return errors.SDLError.SurfaceCreationFailed;

        return Surface{ .handle = handle };
    }

    /// Load a surface from a file
    pub fn loadBMP(path: [:0]const u8) !Surface {
        const handle = c.SDL_LoadBMP(path) orelse return errors.SDLError.SurfaceCreationFailed;
        return Surface{ .handle = handle };
    }

    /// Destroy the surface
    pub fn destroy(self: *Surface) void {
        c.SDL_DestroySurface(self.handle);
    }

    /// Get the surface width
    pub fn width(self: Surface) i32 {
        return @as(i32, @intCast(self.handle.w));
    }

    /// Get the surface height
    pub fn height(self: Surface) i32 {
        return @as(i32, @intCast(self.handle.h));
    }

    /// Get the surface pitch (bytes per row)
    pub fn pitch(self: Surface) i32 {
        return @as(i32, @intCast(self.handle.pitch));
    }

    /// Lock the surface for direct pixel access
    pub fn lock(self: Surface) !void {
        if (!c.SDL_LockSurface(self.handle)) {
            return errors.SDLError.SurfaceLockFailed;
        }
    }

    /// Unlock the surface
    pub fn unlock(self: Surface) void {
        c.SDL_UnlockSurface(self.handle);
    }

    /// Fill the surface with a color
    pub fn fill(self: Surface, color: pixel_mod.Color) !void {
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return errors.SDLError.PixelFormatError;
        const pixel = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (!c.SDL_FillSurfaceRect(self.handle, null, pixel)) {
            return error.SurfaceFillFailed;
        }
    }

    /// Fill a rectangle in the surface with a color
    pub fn fillRect(self: Surface, rect_: rect.Rect, color: pixel_mod.Color) !void {
        const sdl_rect = rect_.toSDL();
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return errors.SDLError.PixelFormatError;
        const pixel = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (!c.SDL_FillSurfaceRect(self.handle, &sdl_rect, pixel)) {
            return error.SurfaceFillFailed;
        }
    }

    /// Blit (copy) another surface onto this one
    pub fn blit(self: Surface, source: Surface, dst_rect: ?rect.Rect) !void {
        const sdl_rect = if (dst_rect) |r| r.toSDL() else null;
        if (!c.SDL_BlitSurface(source.handle, null, self.handle, if (sdl_rect) |*r| r else null)) {
            return error.SurfaceBlitFailed;
        }
    }

    /// Blit (copy) a portion of another surface onto this one
    pub fn blitRect(self: Surface, source: Surface, src_rect: rect.Rect, dst_rect: rect.Rect) !void {
        const sdl_src_rect = src_rect.toSDL();
        const sdl_dst_rect = dst_rect.toSDL();
        if (!c.SDL_BlitSurface(source.handle, &sdl_src_rect, self.handle, &sdl_dst_rect)) {
            return error.SurfaceBlitFailed;
        }
    }

    /// Save the surface to a BMP file
    pub fn saveBMP(self: Surface, path: [:0]const u8) !void {
        if (!c.SDL_SaveBMP(self.handle, path)) {
            return errors.SDLError.SurfaceSaveFailed;
        }
    }

    /// Get direct access to the pixel buffer
    pub fn pixels(self: Surface) [*]u8 {
        return @as([*]u8, @ptrCast(self.handle.pixels));
    }

    /// Get the pixel format
    pub fn getFormat(self: Surface) *c.SDL_PixelFormat {
        return self.handle.format;
    }

    /// Set the color key (transparent pixel value)
    pub fn setColorKey(self: Surface, color: pixel_mod.Color) !void {
        const format = c.SDL_GetPixelFormatDetails(self.handle.format) orelse return errors.SDLError.PixelFormatError;
        const key = c.SDL_MapRGBA(
            format,
            null,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        if (!c.SDL_SetSurfaceColorKey(self.handle, 1, key)) {
            return errors.SDLError.SurfaceOperationFailed;
        }
    }

    /// Set the alpha modulation
    pub fn setAlphaMod(self: Surface, alpha: u8) !void {
        if (!c.SDL_SetSurfaceAlphaMod(self.handle, alpha)) {
            return errors.SDLError.SurfaceOperationFailed;
        }
    }

    /// Set the color modulation
    pub fn setColorMod(self: Surface, color: pixel_mod.Color) !void {
        if (!c.SDL_SetSurfaceColorMod(self.handle, color.r, color.g, color.b)) {
            return errors.SDLError.SurfaceOperationFailed;
        }
    }
};

test "surface operations" {
    try core.init.init(.{ .video = true });
    defer core.init.quit();

    // Create a surface
    var surface = try Surface.create(100, 100, c.SDL_PIXELFORMAT_RGBA32);
    defer surface.destroy();

    // Test dimensions
    try testing.expectEqual(@as(i32, 100), surface.width());
    try testing.expectEqual(@as(i32, 100), surface.height());

    // Fill with a color
    try surface.fill(pixel_mod.Colors.red);

    // Fill a rectangle
    try surface.fillRect(rect.Rect.init(10, 10, 80, 80), pixel_mod.Colors.blue);

    // Create another surface and blit
    var surface2 = try Surface.create(50, 50, c.SDL_PIXELFORMAT_RGBA32);
    defer surface2.destroy();

    try surface2.fill(pixel_mod.Colors.green);
    try surface.blit(surface2, rect.Rect.init(25, 25, 50, 50));

    // Test pixel manipulation
    try surface.lock();
    defer surface.unlock();

    const pixel_ptr = surface.pixels();
    _ = pixel_ptr; // Use the pixel buffer if needed

    // Test color modulation
    try surface.setColorMod(pixel_mod.Colors.white);
    try surface.setAlphaMod(128);
}
