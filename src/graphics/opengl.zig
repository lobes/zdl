//! OpenGL functionality for SDL3.
//!
//! This module provides OpenGL context management:
//! - Context creation and management
//! - Extension loading
//! - Attribute control
//! - Version control
//!
//! Dependencies:
//! - Core SDL3 OpenGL functionality
//! - Video subsystem for window management
//!
//! Thread safety: OpenGL contexts are thread-specific.
//! Each thread needs its own context.
//!
//! Example:
//! ```zig
//! // Set OpenGL attributes
//! try opengl.setAttribute(.context_major_version, 3);
//! try opengl.setAttribute(.context_minor_version, 3);
//! try opengl.setAttribute(.context_profile_mask, .core);
//!
//! // Create window with OpenGL context
//! const window = try video.createWindow(
//!     "OpenGL",
//!     .centered, .centered,
//!     800, 600,
//!     .{ .opengl = true },
//! );
//! defer window.destroy();
//!
//! const gl_context = try opengl.createContext(window);
//! defer gl_context.delete();
//!
//! // Make context current
//! try gl_context.makeCurrent(window);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// OpenGL context handle
pub const GLContext = struct {
    handle: *c.SDL_GLContext,

    /// Delete an OpenGL context
    pub fn delete(self: GLContext) void {
        c.SDL_GL_DeleteContext(self.handle);
    }

    /// Set a window's OpenGL context as current
    pub fn makeCurrent(self: GLContext, window: *c.SDL_Window) !void {
        if (!c.SDL_GL_MakeCurrent(window, self.handle)) {
            return error.MakeContextCurrentFailed;
        }
    }
};

/// OpenGL attribute
pub const GLattr = enum(i32) {
    red_size = c.SDL_GL_RED_SIZE,
    green_size = c.SDL_GL_GREEN_SIZE,
    blue_size = c.SDL_GL_BLUE_SIZE,
    alpha_size = c.SDL_GL_ALPHA_SIZE,
    buffer_size = c.SDL_GL_BUFFER_SIZE,
    doublebuffer = c.SDL_GL_DOUBLEBUFFER,
    depth_size = c.SDL_GL_DEPTH_SIZE,
    stencil_size = c.SDL_GL_STENCIL_SIZE,
    accum_red_size = c.SDL_GL_ACCUM_RED_SIZE,
    accum_green_size = c.SDL_GL_ACCUM_GREEN_SIZE,
    accum_blue_size = c.SDL_GL_ACCUM_BLUE_SIZE,
    accum_alpha_size = c.SDL_GL_ACCUM_ALPHA_SIZE,
    stereo = c.SDL_GL_STEREO,
    multisamplebuffers = c.SDL_GL_MULTISAMPLEBUFFERS,
    multisamplesamples = c.SDL_GL_MULTISAMPLESAMPLES,
    accelerated_visual = c.SDL_GL_ACCELERATED_VISUAL,
    retained_backing = c.SDL_GL_RETAINED_BACKING,
    context_major_version = c.SDL_GL_CONTEXT_MAJOR_VERSION,
    context_minor_version = c.SDL_GL_CONTEXT_MINOR_VERSION,
    context_flags = c.SDL_GL_CONTEXT_FLAGS,
    context_profile_mask = c.SDL_GL_CONTEXT_PROFILE_MASK,
    share_with_current_context = c.SDL_GL_SHARE_WITH_CURRENT_CONTEXT,
    framebuffer_srgb_capable = c.SDL_GL_FRAMEBUFFER_SRGB_CAPABLE,
    context_release_behavior = c.SDL_GL_CONTEXT_RELEASE_BEHAVIOR,
    context_reset_notification = c.SDL_GL_CONTEXT_RESET_NOTIFICATION,
    context_no_error = c.SDL_GL_CONTEXT_NO_ERROR,
    floatbuffers = c.SDL_GL_FLOATBUFFERS,
};

/// OpenGL profile type
pub const GLprofile = enum(i32) {
    core = c.SDL_GL_CONTEXT_PROFILE_CORE,
    compatibility = c.SDL_GL_CONTEXT_PROFILE_COMPATIBILITY,
    es = c.SDL_GL_CONTEXT_PROFILE_ES,
};

/// Create an OpenGL context for a window
pub fn createContext(window: *c.SDL_Window) !GLContext {
    const context = c.SDL_GL_CreateContext(window) orelse return error.CreateContextFailed;
    return GLContext{ .handle = context };
}

/// Set an OpenGL attribute
pub fn setAttribute(attr: GLattr, value: anytype) !void {
    const val = switch (@TypeOf(value)) {
        GLprofile => @intFromEnum(value),
        else => value,
    };
    if (!c.SDL_GL_SetAttribute(@intFromEnum(attr), val)) {
        return error.SetAttributeFailed;
    }
}

/// Get an OpenGL attribute
pub fn getAttribute(attr: GLattr) !i32 {
    var value: i32 = undefined;
    if (!c.SDL_GL_GetAttribute(@intFromEnum(attr), &value)) {
        return error.GetAttributeFailed;
    }
    return value;
}

/// Swap the OpenGL buffers for a window, if double-buffering is supported
pub fn swapWindow(window: *c.SDL_Window) void {
    c.SDL_GL_SwapWindow(window);
}

/// Set the swap interval for the current OpenGL context
pub fn setSwapInterval(interval: i32) !void {
    if (!c.SDL_GL_SetSwapInterval(interval)) {
        return error.SetSwapIntervalFailed;
    }
}

/// Get the swap interval for the current OpenGL context
pub fn getSwapInterval() i32 {
    return c.SDL_GL_GetSwapInterval();
}

/// Get the address of an OpenGL function
pub fn getProcAddress(proc: [:0]const u8) ?*anyopaque {
    return c.SDL_GL_GetProcAddress(proc.ptr);
}

/// Check if an OpenGL extension is supported
pub fn extensionSupported(extension: [:0]const u8) bool {
    return c.SDL_GL_ExtensionSupported(extension.ptr) == c.SDL_TRUE;
}

/// Reset all OpenGL attributes to their default values
pub fn resetAttributes() void {
    c.SDL_GL_ResetAttributes();
}

test "opengl basics" {
    try core.init.init(.{ .video = true });
    defer core.init.quit();

    // Set OpenGL attributes
    try setAttribute(.context_major_version, 3);
    try setAttribute(.context_minor_version, 3);
    try setAttribute(.context_profile_mask, GLprofile.core);

    // Verify attributes were set
    const major = try getAttribute(.context_major_version);
    try std.testing.expectEqual(@as(i32, 3), major);

    const minor = try getAttribute(.context_minor_version);
    try std.testing.expectEqual(@as(i32, 3), minor);

    const profile = try getAttribute(.context_profile_mask);
    try std.testing.expectEqual(@as(i32, @intFromEnum(GLprofile.core)), profile);

    // Reset attributes
    resetAttributes();

    // Test extension query (may not exist)
    _ = extensionSupported("GL_ARB_vertex_array_object");
}
