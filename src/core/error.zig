//! Error handling utilities for SDL3.
//!
//! This module provides error handling and reporting functionality:
//! - Error code definitions
//! - Error message management
//! - Error reporting utilities
//! - Error clearing and setting
//!
//! Dependencies:
//! - Core SDL3 error handling
//! - SDL_ttf for font-related errors
//!
//! Thread safety: SDL's error handling is thread-local. Each thread maintains
//! its own error message, so error operations are thread-safe.
//!
//! Memory management: Error messages are managed by SDL. No explicit cleanup
//! is required for error handling operations.
//!
//! Example:
//! ```zig
//! // Check and handle SDL errors
//! if (someSDLFunction()) |result| {
//!     // Success case
//! } else |err| {
//!     const msg = getError();
//!     std.log.err("SDL error: {s}", .{msg});
//!     return err;
//! }
//!
//! // Set custom error
//! setError("Custom error message");
//! // Clear error state
//! clearError();
//! ```

const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const std = @import("std");

/// Get the last error message that SDL generated
pub fn getError() []const u8 {
    return std.mem.span(c.SDL_GetError());
}

/// Clear the current error message
pub fn clearError() void {
    _ = c.SDL_ClearError();
}

/// Set the error message
pub fn setError(msg: [:0]const u8) void {
    _ = c.SDL_SetError(msg);
}

pub const SDLError = error{
    InitializationFailed,
    WindowCreationFailed,
    RendererCreationFailed,
    SurfaceCreationFailed,
    TextureCreationFailed,
    TextureQueryFailed,
    PixelFormatError,
    TTFInitializationFailed,
    FontLoadFailed,
    TextRenderFailed,
    SurfaceLockFailed,
    SurfaceOperationFailed,
};

test "error handling" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    setError("Test error");
    try std.testing.expectEqualStrings("Test error", getError());
    clearError();
    try std.testing.expectEqualStrings("", getError());
}
