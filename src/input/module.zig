//! Input device handling for SDL3.
//!
//! This module provides support for various input devices:
//! - Modern gamepad support
//! - Keyboard input
//! - Mouse and cursor control
//! - Touch input
//! - Pen/stylus support
//! - Force feedback
//! - Sensor integration
//! - Camera capture
//! - Low-level joystick access
//!
//! Each input type has its own submodule with specific functionality
//! while sharing common patterns for device enumeration and event handling.

// Currently implemented
pub const gamepad = @import("gamepad.zig");
pub const joystick = @import("joystick.zig");
pub const keyboard = @import("keyboard.zig");
pub const mouse = @import("mouse.zig");
pub const touch = @import("touch.zig");
pub const haptic = @import("haptic.zig");
pub const sensor = @import("sensor.zig");

comptime {
    // Import and test implemented modules
    _ = gamepad;
    _ = joystick;
    _ = keyboard;
    _ = mouse;
    _ = touch;
    _ = haptic;
    _ = sensor;
}
