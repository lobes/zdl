const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");

/// RGBA color representation
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    /// Create a new color
    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Create a new color from RGB values (alpha = 255)
    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = 255 };
    }

    /// Convert to SDL_Color
    pub fn toSDL(self: Color) c.SDL_Color {
        return .{
            .r = self.r,
            .g = self.g,
            .b = self.b,
            .a = self.a,
        };
    }

    /// Convert to u32 pixel value
    pub fn toU32(self: Color) u32 {
        return @as(u32, self.r) << 24 |
            @as(u32, self.g) << 16 |
            @as(u32, self.b) << 8 |
            @as(u32, self.a);
    }

    /// Create a color from a u32 pixel value
    pub fn fromU32(pixel: u32) Color {
        return .{
            .r = @truncate((pixel >> 24) & 0xFF),
            .g = @truncate((pixel >> 16) & 0xFF),
            .b = @truncate((pixel >> 8) & 0xFF),
            .a = @truncate(pixel & 0xFF),
        };
    }
};

/// Common colors
pub const Colors = struct {
    pub const black = Color.rgb(0, 0, 0);
    pub const white = Color.rgb(255, 255, 255);
    pub const red = Color.rgb(255, 0, 0);
    pub const green = Color.rgb(0, 255, 0);
    pub const blue = Color.rgb(0, 0, 255);
    pub const yellow = Color.rgb(255, 255, 0);
    pub const magenta = Color.rgb(255, 0, 255);
    pub const cyan = Color.rgb(0, 255, 255);
    pub const transparent = Color.init(0, 0, 0, 0);
};

/// Pixel format representation
pub const PixelFormat = struct {
    handle: [*c]const c.SDL_PixelFormatDetails,

    /// Create a new pixel format from a format value
    pub fn init(format: u32) !PixelFormat {
        const handle = c.SDL_GetPixelFormatDetails(format) orelse return error.PixelFormatError;
        return PixelFormat{ .handle = handle };
    }

    /// Destroy the pixel format
    pub fn deinit(self: PixelFormat) void {
        _ = self;
    }

    /// Get the bits per pixel
    pub fn bitsPerPixel(self: PixelFormat) u8 {
        return self.handle.BitsPerPixel;
    }

    /// Get the bytes per pixel
    pub fn bytesPerPixel(self: PixelFormat) u8 {
        return self.handle.BytesPerPixel;
    }

    /// Map a color to a pixel value
    pub fn mapRGBA(self: PixelFormat, color: Color) u32 {
        return c.SDL_MapRGBA(self.handle, null, color.r, color.g, color.b, color.a);
    }

    /// Get the color from a pixel value
    pub fn getRGBA(self: PixelFormat, pixel: u32) Color {
        var r: u8 = undefined;
        var g: u8 = undefined;
        var b: u8 = undefined;
        var a: u8 = undefined;
        c.SDL_GetRGBA(pixel, self.handle, null, &r, &g, &b, &a);
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }
};

test "color operations" {
    // Test color creation and conversion
    const color = Color.rgb(255, 128, 64);
    try std.testing.expectEqual(@as(u8, 255), color.r);
    try std.testing.expectEqual(@as(u8, 128), color.g);
    try std.testing.expectEqual(@as(u8, 64), color.b);
    try std.testing.expectEqual(@as(u8, 255), color.a);

    // Test u32 conversion
    const pixel = color.toU32();
    const color2 = Color.fromU32(pixel);
    try std.testing.expectEqual(color.r, color2.r);
    try std.testing.expectEqual(color.g, color2.g);
    try std.testing.expectEqual(color.b, color2.b);
    try std.testing.expectEqual(color.a, color2.a);

    // Test common colors
    try std.testing.expectEqual(@as(u8, 255), Colors.red.r);
    try std.testing.expectEqual(@as(u8, 0), Colors.red.g);
    try std.testing.expectEqual(@as(u8, 0), Colors.red.b);
    try std.testing.expectEqual(@as(u8, 255), Colors.red.a);
}

test "pixel format operations" {
    const init = @import("init.zig");
    try init.init(.{ .video = true });
    defer init.quit();

    var format = try PixelFormat.init(c.SDL_PIXELFORMAT_RGBA32);
    defer format.deinit();

    const color = Color.rgb(255, 128, 64);
    const pixel = format.mapRGBA(color);
    const color2 = format.getRGBA(pixel);

    try std.testing.expectEqual(color.r, color2.r);
    try std.testing.expectEqual(color.g, color2.g);
    try std.testing.expectEqual(color.b, color2.b);
    try std.testing.expectEqual(color.a, color2.a);
}
