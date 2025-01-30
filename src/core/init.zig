//! SDL3 initialization and shutdown management.
//!
//! This module provides safe initialization and shutdown of SDL subsystems:
//! - Subsystem initialization flags
//! - Safe initialization with error handling
//! - Automatic subsystem dependency management
//! - Clean shutdown handling
//!
//! Dependencies:
//! - Core SDL3 initialization
//! - Uses error.zig for error handling
//!
//! Thread safety: SDL initialization should be done from the main thread.
//! Once initialized, most subsystems are thread-safe for their specific
//! operations.
//!
//! Platform notes:
//! - Some subsystems may not be available on all platforms
//! - Video subsystem behavior varies by platform
//! - Audio subsystem requirements differ by platform
//!
//! Example:
//! ```zig
//! // Initialize SDL with video and audio
//! try init(.{
//!     .video = true,
//!     .audio = true,
//! });
//! defer quit();
//!
//! // Use SDL functionality...
//! ```

const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");
const core = @import("../core/module.zig");
const errors = core.errors;

pub const InitFlags = struct {
    audio: bool = false,
    video: bool = false,
    joystick: bool = false,
    haptic: bool = false,
    gamepad: bool = false,
    events: bool = true,
    sensor: bool = false,
    camera: bool = false,

    pub fn toSDLFlags(self: InitFlags) u32 {
        var flags: u32 = 0;
        if (self.audio) flags |= c.SDL_INIT_AUDIO;
        if (self.video) flags |= c.SDL_INIT_VIDEO;
        if (self.joystick) flags |= c.SDL_INIT_JOYSTICK;
        if (self.haptic) flags |= c.SDL_INIT_HAPTIC;
        if (self.gamepad) flags |= c.SDL_INIT_GAMEPAD;
        if (self.events) flags |= c.SDL_INIT_EVENTS;
        if (self.sensor) flags |= c.SDL_INIT_SENSOR;
        if (self.camera) flags |= c.SDL_INIT_CAMERA;
        return flags;
    }
};

/// Initialize SDL with the specified subsystems
pub fn init(flags: InitFlags) !void {
    if (!c.SDL_Init(flags.toSDLFlags())) {
        return errors.SDLError.InitializationFailed;
    }
}

/// Quit SDL and all initialized subsystems
pub fn quit() void {
    c.SDL_Quit();
}

const testing = @import("std").testing;

test "initialization" {
    try init(.{ .video = true });
    defer quit();

    // Test that SDL is properly initialized
    try testing.expect(c.SDL_WasInit(c.SDL_INIT_VIDEO) != 0);
}
