const std = @import("std");
const zdl = @import("../../zdl.zig");
const c = zdl.c;

pub fn init() !void {
    if (c.TTF_Init() < 0) {
        return error.TTFInitFailed;
    }
}

pub fn quit() void {
    c.TTF_Quit();
}

pub const Font = struct {
    handle: *c.TTF_Font,

    pub fn loadFromFile(path: [:0]const u8, point_size: f32) !Font {
        const handle = c.TTF_OpenFont(path.ptr, @as(c_int, @intFromFloat(point_size))) orelse return error.TTFFontLoadFailed;
        return Font{ .handle = handle };
    }

    pub fn destroy(self: *Font) void {
        c.TTF_CloseFont(self.handle);
    }

    pub fn renderSolid(self: Font, text: [:0]const u8, color: zdl.pixels.Color) !zdl.surface.Surface {
        const sdl_color = color.toSDL();
        return c.TTF_RenderUTF8_Solid(self.handle, text.ptr, sdl_color) orelse return error.TTFRenderError;
    }

    pub fn renderShaded(
        self: Font,
        text: [:0]const u8,
        fg_color: zdl.pixels.Color,
        bg_color: zdl.pixels.Color,
    ) !zdl.surface.Surface {
        return c.TTF_RenderUTF8_Shaded(self.handle, text.ptr, fg_color, bg_color) orelse return error.TTFRenderError;
    }

    pub fn renderBlended(self: Font, text: [:0]const u8, color: zdl.pixels.Color) !zdl.surface.Surface {
        const sdl_color = color.toSDL();
        return c.TTF_RenderUTF8_Blended(self.handle, text.ptr, sdl_color) orelse return error.TTFRenderError;
    }
};

test {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    try init();
    defer quit();

    // Load a test font
    var font = try Font.loadFromFile("test.ttf", 16);
    defer font.destroy();
}
