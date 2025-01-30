//! SDL3 bindings for Zig.
//!
//! This module provides a comprehensive, idiomatic Zig wrapper around SDL3.
//! It is organized into several major subsystems:
//!
//! Core functionality:
//! ```zig
//! const sdl = @import("sdl3.zig");
//! try sdl.core.init.init();
//! defer sdl.core.init.quit();
//! ```
//!
//! Video and rendering:
//! ```zig
//! const window = try sdl.video.window.Window.create("Title", 800, 600, .{});
//! defer window.destroy();
//! ```
//!
//! Input handling:
//! ```zig
//! const gamepad = try sdl.input.gamepad.Gamepad.open(0);
//! defer gamepad.close();
//! ```
//!
//! Each module provides detailed documentation and examples for its functionality.

pub const core = @import("core/module.zig");
pub const video = @import("video/module.zig");
pub const input = @import("input/module.zig");
pub const audio = @import("audio/module.zig");
pub const system = @import("system/module.zig");
pub const graphics = @import("graphics/module.zig");
pub const mixer = @import("mixer/module.zig");
pub const ttf = @import("ttf/module.zig");

test {
    // Test all public modules
    _ = core;
    _ = video;
    _ = input;
    _ = audio;
    _ = system;
    _ = graphics;
    _ = mixer;
    _ = ttf;
}
