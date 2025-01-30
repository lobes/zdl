//! Vulkan functionality for SDL3.
//!
//! This module provides Vulkan integration:
//! - Instance creation
//! - Surface management
//! - Device selection
//! - Extension handling
//!
//! Dependencies:
//! - Core SDL3 Vulkan functionality
//! - Video subsystem for window management
//!
//! Thread safety: Vulkan objects must be externally synchronized
//! according to the Vulkan specification.
//!
//! Example:
//! ```zig
//! // Get required instance extensions
//! const extensions = try vulkan.getInstanceExtensions();
//! defer extensions.deinit();
//!
//! // Create window with Vulkan support
//! const window = try video.createWindow(
//!     "Vulkan",
//!     .centered, .centered,
//!     800, 600,
//!     .{ .vulkan = true },
//! );
//! defer window.destroy();
//!
//! // Create Vulkan surface
//! const surface = try vulkan.createSurface(window, instance);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Required Vulkan instance extensions
pub const InstanceExtensions = struct {
    names: []const [*:0]const u8,
    count: u32,
    allocator: std.mem.Allocator,

    /// Free the extension names
    pub fn deinit(self: InstanceExtensions) void {
        self.allocator.free(self.names);
    }
};

/// Get the names of the Vulkan instance extensions needed by SDL
pub fn getInstanceExtensions() !InstanceExtensions {
    var count: u32 = undefined;
    if (!c.SDL_Vulkan_GetInstanceExtensions(&count, null)) {
        return error.GetInstanceExtensionsFailed;
    }

    const names = try std.heap.c_allocator.alloc([*:0]const u8, count);
    errdefer std.heap.c_allocator.free(names);

    if (!c.SDL_Vulkan_GetInstanceExtensions(&count, @ptrCast(names.ptr))) {
        return error.GetInstanceExtensionsFailed;
    }

    return InstanceExtensions{
        .names = names,
        .count = count,
        .allocator = std.heap.c_allocator,
    };
}

/// Create a Vulkan surface for a window
pub fn createSurface(window: *c.SDL_Window, instance: *anyopaque) !*anyopaque {
    var surface: *anyopaque = undefined;
    if (!c.SDL_Vulkan_CreateSurface(window, @ptrCast(instance), &surface)) {
        return error.CreateSurfaceFailed;
    }
    return surface;
}

/// Get the size of a window's drawable area in pixels
pub fn getDrawableSize(window: *c.SDL_Window) struct { width: i32, height: i32 } {
    var w: i32 = undefined;
    var h: i32 = undefined;
    c.SDL_Vulkan_GetDrawableSize(window, &w, &h);
    return .{ .width = w, .height = h };
}

test "vulkan basics" {
    try core.init.init(.{ .video = true });
    defer core.init.quit();

    // Get required instance extensions
    const extensions = try getInstanceExtensions();
    defer extensions.deinit();

    // Should have at least one extension
    try std.testing.expect(extensions.count > 0);
    try std.testing.expect(extensions.names.len == extensions.count);

    // Each extension name should be valid
    for (extensions.names) |name| {
        const str = std.mem.span(name);
        try std.testing.expect(str.len > 0);
    }
}
