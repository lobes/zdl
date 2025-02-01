//! Video and rendering functionality for SDL3.
//!
//! This module provides graphics capabilities:
//! - Window creation and management
//! - Hardware-accelerated 2D rendering
//! - Modern GPU features
//! - Surface operations
//! - Pixel format handling
//! - Rectangle utilities
//!
//! Window management:
//! ```zig
//! // Create a window
//! const window = try Window.create(
//!     "My Window",
//!     800, 600,
//!     .{ .shown = true },
//! );
//! defer window.destroy();
//! ```
//!
//! 2D rendering:
//! ```zig
//! // Create renderer
//! const renderer = try Renderer.create(window, .{
//!     .accelerated = true,
//!     .vsync = true,
//! });
//! defer renderer.destroy();
//!
//! // Draw something
//! try renderer.setColor(Colors.red);
//! try renderer.clear();
//! try renderer.present();
//! ```
//!
//! Surface operations:
//! ```zig
//! // Load and display an image
//! const surface = try Surface.loadBMP("image.bmp");
//! defer surface.destroy();
//!
//! const texture = try renderer.createTextureFromSurface(surface);
//! defer texture.destroy();
//! ```
//!
//! GPU features:
//! ```zig
//! // Use modern GPU features
//! const gpu = try video.gpu.init(window);
//! defer gpu.quit();
//!
//! try gpu.setDrawColor(255, 0, 0, 255);
//! try gpu.clear();
//! gpu.present();
//! ```

const window = @import("window.zig");
const render = @import("render.zig");
const surface = @import("surface.zig");
pub const pixels = @import("pixels.zig");
pub const rect = @import("rect.zig");

pub const Window = window.Window;
pub const Renderer = render.Renderer;
pub const Surface = surface.Surface;
pub const Colors = pixels.Colors;
pub const Rect = rect.Rect;

test {
    // Test all public modules
    _ = window;
    _ = render;
    _ = surface;
    _ = pixels;
    _ = rect;
}
