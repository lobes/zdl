//! Video and rendering functionality for SDL3.
//!
//! This module provides comprehensive support for:
//! - Window management
//! - 2D rendering
//! - Surface operations
//! - Pixel format handling
//! - Modern GPU features
//! - Geometric primitives
//!
//! The video module is essential for any application that needs to create windows
//! or perform rendering operations.

pub const window = @import("window.zig");
pub const render = @import("render.zig");
pub const surface = @import("surface.zig");
pub const pixels = @import("pixels.zig");
pub const rect = @import("rect.zig");
pub const gpu = @import("gpu.zig");

comptime {
    // Import and test all video modules
    _ = window;
    _ = render;
    _ = surface;
    _ = pixels;
    _ = rect;
    _ = gpu;
}
