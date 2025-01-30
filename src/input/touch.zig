//! Touch and gesture functionality for SDL3.
//!
//! This module provides touch input handling:
//! - Multi-touch support
//! - Gesture recognition
//! - Finger tracking
//! - Touch device management
//!
//! Dependencies:
//! - Core SDL3 touch functionality
//! - Events system for touch events
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Enable gesture events
//! touch.loadDollarTemplates();
//! defer touch.unloadDollarTemplates();
//!
//! // Record a gesture
//! const gesture = try touch.recordGesture(touch_id);
//! if (gesture) {
//!     // Gesture recorded successfully
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Touch device type
pub const TouchDeviceType = enum(i32) {
    invalid = c.SDL_TOUCH_DEVICE_INVALID,
    direct = c.SDL_TOUCH_DEVICE_DIRECT,
    indirect_absolute = c.SDL_TOUCH_DEVICE_INDIRECT_ABSOLUTE,
    indirect_relative = c.SDL_TOUCH_DEVICE_INDIRECT_RELATIVE,
};

/// Get the number of registered touch devices
pub fn getNumTouchDevices() i32 {
    return c.SDL_GetNumTouchDevices();
}

/// Get the touch ID with the given index
pub fn getTouchDevice(index: i32) i64 {
    return c.SDL_GetTouchDevice(index);
}

/// Get the type of the touch device
pub fn getTouchDeviceType(touch_id: i64) TouchDeviceType {
    return @enumFromInt(c.SDL_GetTouchDeviceType(touch_id));
}

/// Get the number of active fingers for a touch device
pub fn getNumTouchFingers(touch_id: i64) i32 {
    return c.SDL_GetNumTouchFingers(touch_id);
}

/// Get the finger object for specified touch device and finger index
pub fn getTouchFinger(touch_id: i64, index: i32) ?*c.SDL_Finger {
    return c.SDL_GetTouchFinger(touch_id, index);
}

/// Load the Dollar Gesture templates from a file
pub fn loadDollarTemplates(touch_id: i64, src: [:0]const u8) !i32 {
    const loaded = c.SDL_LoadDollarTemplates(touch_id, src.ptr);
    if (loaded < 0) return error.LoadDollarTemplatesFailed;
    return loaded;
}

/// Save all currently loaded Dollar Gesture templates
pub fn saveDollarTemplates(touch_id: i64, dst: [:0]const u8) !i32 {
    const saved = c.SDL_SaveDollarTemplates(touch_id, dst.ptr);
    if (saved < 0) return error.SaveDollarTemplatesFailed;
    return saved;
}

/// Begin recording a gesture on a specified touch device
pub fn recordGesture(touch_id: i64) !bool {
    return c.SDL_RecordGesture(touch_id) == 1;
}

/// Get the platform dependent name of a touch device
pub fn getTouchDeviceName(touch_id: i64) ?[:0]const u8 {
    const name = c.SDL_GetTouchDeviceName(touch_id) orelse return null;
    return std.mem.span(name);
}

test "touch basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get number of touch devices
    const num_devices = getNumTouchDevices();
    try std.testing.expect(num_devices >= 0);

    // Skip test if no touch devices
    if (num_devices == 0) return;

    // Get first touch device
    const touch_id = getTouchDevice(0);
    try std.testing.expect(touch_id >= 0);

    // Get device info
    const device_type = getTouchDeviceType(touch_id);
    try std.testing.expect(@intFromEnum(device_type) >= 0);

    const num_fingers = getNumTouchFingers(touch_id);
    try std.testing.expect(num_fingers >= 0);

    // Try to get device name
    const name = getTouchDeviceName(touch_id);
    if (name) |n| try std.testing.expect(n.len > 0);

    // Test gesture recording
    _ = recordGesture(touch_id) catch {};
}
