//! Core functionality for SDL3.
//!
//! This module provides fundamental SDL3 features:
//! - System initialization and shutdown
//! - Event handling and processing
//! - High-resolution timing
//! - Properties system
//! - Runtime configuration
//! - Logging system
//! - Version information
//!
//! Most applications will start with initialization:
//! ```zig
//! // Initialize SDL with required subsystems
//! try zdl.init(.{
//!     .video = true,
//!     .audio = true,
//! });
//! defer zdl.quit();
//! ```
//!
//! Event handling:
//! ```zig
//! while (zdl.events.pollEvent()) |event| {
//!     switch (event) {
//!         .quit => break,
//!         else => {},
//!     }
//! }
//! ```
//!
//! Timing:
//! ```zig
//! const start = zdl.timer.getTicks();
//! zdl.timer.delay(16); // 60 FPS
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// Initialize SDL with the specified subsystems
pub fn init(flags: struct {
    audio: bool = false,
    video: bool = false,
    joystick: bool = false,
    haptic: bool = false,
    gamepad: bool = false,
    events: bool = true,
    sensor: bool = false,
    camera: bool = false,
}) !void {
    var sdl_flags: u32 = 0;
    if (flags.audio) sdl_flags |= c.SDL_INIT_AUDIO;
    if (flags.video) sdl_flags |= c.SDL_INIT_VIDEO;
    if (flags.joystick) sdl_flags |= c.SDL_INIT_JOYSTICK;
    if (flags.haptic) sdl_flags |= c.SDL_INIT_HAPTIC;
    if (flags.gamepad) sdl_flags |= c.SDL_INIT_GAMEPAD;
    if (flags.events) sdl_flags |= c.SDL_INIT_EVENTS;
    if (flags.sensor) sdl_flags |= c.SDL_INIT_SENSOR;
    if (flags.camera) sdl_flags |= c.SDL_INIT_CAMERA;

    if (!c.SDL_Init(sdl_flags)) {
        return error.SDLError;
    }
}

/// Quit SDL and all initialized subsystems
pub fn quit() void {
    c.SDL_Quit();
}

pub const events = @import("events.zig");
pub const timer = @import("timer.zig");
pub const props = @import("props.zig");
pub const hints = @import("hints.zig");
pub const log = @import("log.zig");
pub const version = @import("version.zig");

test {
    // Test all public modules
    _ = events;
    _ = timer;
    _ = props;
    _ = hints;
    _ = log;
    _ = version;
}
