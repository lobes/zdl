const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const std = @import("std");
const errors = @import("../core/module.zig");
const pixels = @import("../graphics/module.zig");
const render = @import("../graphics/module.zig");

pub const Font = struct {
    handle: *c.TTF_Font,

    /// Initialize the TTF system
    pub fn init() !void {
        if (!c.TTF_Init()) {
            return errors.SDLError.TTFInitializationFailed;
        }
    }

    /// Quit the TTF system
    pub fn quit() void {
        c.TTF_Quit();
    }

    /// Load a font from a file with a given point size
    pub fn load(path: []const u8, point_size: f32) !Font {
        const handle = c.TTF_OpenFont(path.ptr, point_size) orelse return errors.SDLError.FontLoadFailed;
        return Font{ .handle = handle };
    }

    /// Close and free a previously loaded font
    pub fn close(self: *Font) void {
        c.TTF_CloseFont(self.handle);
    }

    /// Render text as a solid surface (quick and dirty)
    pub fn renderSolid(self: Font, text: []const u8, color: pixels.Color) !*c.SDL_Surface {
        const sdl_color = c.SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
        return c.TTF_RenderText_Solid(self.handle, text.ptr, text.len, sdl_color) orelse return errors.SDLError.TextRenderFailed;
    }

    /// Render text as a shaded surface (slow but nice)
    pub fn renderShaded(self: Font, text: []const u8, fg: pixels.Color, bg: pixels.Color) !*c.SDL_Surface {
        const fg_color = c.SDL_Color{ .r = fg.r, .g = fg.g, .b = fg.b, .a = fg.a };
        const bg_color = c.SDL_Color{ .r = bg.r, .g = bg.g, .b = bg.b, .a = bg.a };
        return c.TTF_RenderText_Shaded(self.handle, text.ptr, text.len, fg_color, bg_color) orelse return errors.SDLError.TextRenderFailed;
    }

    /// Render text as a blended surface (slow but very nice)
    pub fn renderBlended(self: Font, text: []const u8, color: pixels.Color) !*c.SDL_Surface {
        const sdl_color = c.SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
        return c.TTF_RenderText_Blended(self.handle, text.ptr, text.len, sdl_color) orelse return errors.SDLError.TextRenderFailed;
    }
};

test "font loading and rendering" {
    const init = @import("../core/module.zig");
    try init.init(.{ .video = true });
    defer init.quit();

    try Font.init();
    defer Font.quit();

    var font = try Font.load("/System/Library/Fonts/Helvetica.ttc", 24.0);
    defer font.close();

    const surface = try font.renderBlended("Hello, World!", pixels.Colors.white);
    defer c.SDL_DestroySurface(surface);
}
