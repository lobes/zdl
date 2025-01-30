//! Metal functionality for SDL3.
//!
//! This module provides Metal integration:
//! - View management
//! - Device setup
//! - Command handling
//! - Layer access
//!
//! Dependencies:
//! - Core SDL3 Metal functionality
//! - Video subsystem for window management
//!
//! Thread safety: Metal objects must be externally synchronized
//! according to the Metal specification.
//!
//! Example:
//! ```zig
//! // Create window with Metal support
//! const window = try video.createWindow(
//!     "Metal",
//!     .centered, .centered,
//!     800, 600,
//!     .{ .metal = true },
//! );
//! defer window.destroy();
//!
//! // Get Metal view
//! const view = metal.createView(window);
//! const layer = metal.getLayer(view);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Create a Metal view for a window
pub fn createView(window: *c.SDL_Window) !*anyopaque {
    const view = c.SDL_Metal_CreateView(window) orelse return error.CreateViewFailed;
    return view;
}

/// Destroy a Metal view
pub fn destroyView(view: *anyopaque) void {
    c.SDL_Metal_DestroyView(@ptrCast(view));
}

/// Get the CAMetalLayer backing the Metal view
pub fn getLayer(view: *anyopaque) !*anyopaque {
    const layer = c.SDL_Metal_GetLayer(@ptrCast(view)) orelse return error.GetLayerFailed;
    return layer;
}

/// Get the size of a window's drawable area in pixels
pub fn getDrawableSize(window: *c.SDL_Window) struct { width: i32, height: i32 } {
    var w: i32 = undefined;
    var h: i32 = undefined;
    c.SDL_Metal_GetDrawableSize(window, &w, &h);
    return .{ .width = w, .height = h };
}

test "metal basics" {
    try core.init.init(.{ .video = true });
    defer core.init.quit();

    // Skip test on non-Apple platforms
    if (!@import("builtin").target.isDarwin()) return;

    // Create window with Metal support
    const window = try core.video.createWindow(
        "Metal Test",
        .centered,
        .centered,
        800,
        600,
        .{ .metal = true },
    );
    defer window.destroy();

    // Create Metal view
    const view = try createView(window);
    defer destroyView(view);

    // Get Metal layer
    const layer = try getLayer(view);
    try std.testing.expect(layer != null);

    // Get drawable size
    const size = getDrawableSize(window);
    try std.testing.expect(size.width > 0);
    try std.testing.expect(size.height > 0);
}
