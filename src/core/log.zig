const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn log(message: [:0]const u8) void {
    c.SDL_Log("%s", message.ptr);
}

pub fn logDebug(message: [:0]const u8) void {
    c.SDL_LogDebug(c.SDL_LOG_CATEGORY_APPLICATION, "%s", message.ptr);
}

pub fn logInfo(message: [:0]const u8) void {
    c.SDL_LogInfo(c.SDL_LOG_CATEGORY_APPLICATION, "%s", message.ptr);
}

pub fn logWarn(message: [:0]const u8) void {
    c.SDL_LogWarn(c.SDL_LOG_CATEGORY_APPLICATION, "%s", message.ptr);
}

pub fn logError(message: [:0]const u8) void {
    c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", message.ptr);
}

pub fn logCritical(message: [:0]const u8) void {
    c.SDL_LogCritical(c.SDL_LOG_CATEGORY_APPLICATION, "%s", message.ptr);
}

test "logging operations" {
    const core = @import("module.zig");
    try core.init(.{});
    defer core.quit();

    // Test logging at different levels
    log("Basic log message");
    logDebug("Debug message");
    logInfo("Info message");
    logWarn("Warning message");
    logError("Error message");
    logCritical("Critical message");
}
