//! Graphics API integration for SDL3.
//!
//! This module provides support for multiple graphics APIs:
//! - OpenGL context management and extension loading
//! - Vulkan surface creation and instance management
//! - Metal view and layer handling (Apple platforms)
//!
//! Each API has its own submodule with specific functionality:
//!
//! OpenGL:
//! ```zig
//! // Create OpenGL context
//! try graphics.opengl.setAttribute(.context_major_version, 3);
//! const gl_context = try graphics.opengl.createContext(window);
//! ```
//!
//! Vulkan:
//! ```zig
//! // Get required extensions
//! const extensions = try graphics.vulkan.getInstanceExtensions();
//! const surface = try graphics.vulkan.createSurface(window, instance);
//! ```
//!
//! Metal:
//! ```zig
//! // Create Metal view
//! const view = try graphics.metal.createView(window);
//! const layer = try graphics.metal.getLayer(view);
//! ```
//!
//! Each API requires appropriate window creation flags and platform support.
//! Only use APIs that are available on your target platform.

pub const opengl = @import("opengl.zig");
pub const vulkan = @import("vulkan.zig");
pub const metal = @import("metal.zig");

test {
    // Test all public modules
    _ = opengl;
    _ = vulkan;
    _ = metal;
}
