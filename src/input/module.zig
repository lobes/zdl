//! Input device handling for SDL3.
//!
//! This module provides support for various input devices:
//! - Modern gamepad support
//! - Legacy joystick access
//! - Keyboard input
//! - Mouse and cursor control
//! - Touch input
//! - Force feedback
//! - Sensor integration
//!
//! Gamepad handling:
//! ```zig
//! // Open first available gamepad
//! const gamepad = try input.gamepad.open(0);
//! defer gamepad.close();
//!
//! // Read gamepad state
//! const state = gamepad.getState();
//! if (state.buttons.a) {
//!     // A button is pressed
//! }
//! ```
//!
//! Keyboard input:
//! ```zig
//! // Get keyboard state
//! const state = input.keyboard.getState();
//! if (state[input.keyboard.scancode.space]) {
//!     // Space is pressed
//! }
//! ```
//!
//! Mouse control:
//! ```zig
//! // Get mouse state
//! var x: i32 = undefined;
//! var y: i32 = undefined;
//! const buttons = input.mouse.getGlobalState(&x, &y);
//! ```
//!
//! Touch input:
//! ```zig
//! // Get touch device info
//! const num_devices = input.touch.getNumTouchDevices();
//! if (num_devices > 0) {
//!     const device_id = input.touch.getTouchDevice(0);
//! }
//! ```
//!
//! Force feedback:
//! ```zig
//! // Open haptic device
//! const device = try input.haptic.open(0);
//! defer device.close();
//!
//! // Play rumble effect
//! try device.rumblePlay(0.5, 1000);
//! ```
//!
//! Sensor access:
//! ```zig
//! // Open accelerometer
//! const sensor = try input.sensor.open(.accelerometer);
//! defer sensor.close();
//!
//! // Get sensor data
//! const data = try sensor.getData();
//! ```

pub const gamepad = @import("gamepad.zig");
pub const joystick = @import("joystick.zig");
pub const keyboard = @import("keyboard.zig");
pub const mouse = @import("mouse.zig");
pub const touch = @import("touch.zig");
pub const haptic = @import("haptic.zig");
pub const sensor = @import("sensor.zig");

test {
    // Test all public modules
    _ = gamepad;
    _ = joystick;
    _ = keyboard;
    _ = mouse;
    _ = touch;
    _ = haptic;
    _ = sensor;
}
