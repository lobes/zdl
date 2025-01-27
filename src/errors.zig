const c = @cImport({
    @cInclude("SDL3/SDL.h");
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
    TextureCreationFailed,
    SurfaceCreationFailed,
    SurfaceLockFailed,
    SurfaceSaveFailed,
    SurfaceOperationFailed,
    AudioDeviceError,
    PixelFormatError,
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
