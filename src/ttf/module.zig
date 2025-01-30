//! TrueType font rendering for SDL3.
//!
//! This module provides font rendering capabilities:
//! - TrueType font loading
//! - Text rendering
//! - Font styling
//! - Unicode support
//! - Glyph caching
//!
//! Font loading:
//! ```zig
//! // Initialize TTF
//! try ttf.init();
//! defer ttf.quit();
//!
//! // Load font
//! const font = try ttf.Font.open("font.ttf", 16);
//! defer font.close();
//! ```
//!
//! Basic text rendering:
//! ```zig
//! // Render text
//! const surface = try font.renderText("Hello SDL3!", .solid, .{ .r = 255 });
//! defer surface.destroy();
//!
//! const texture = try renderer.createTextureFromSurface(surface);
//! defer texture.destroy();
//! ```
//!
//! Font styling:
//! ```zig
//! // Set font style
//! font.setStyle(.{
//!     .bold = true,
//!     .italic = true,
//! });
//!
//! // Set outline
//! font.setOutline(1);
//! ```
//!
//! Unicode support:
//! ```zig
//! // Render UTF-8 text
//! const surface = try font.renderUTF8("Hello 世界!", .solid, .{ .r = 255 });
//! defer surface.destroy();
//! ```
//!
//! Note: This module requires SDL_ttf to be installed.

pub const ttf = @import("ttf.zig");

test {
    // Test all public modules
    _ = ttf;
}
