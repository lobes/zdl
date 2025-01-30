//! Force feedback (haptic) functionality for SDL3.
//!
//! This module provides force feedback support:
//! - Device enumeration and management
//! - Effect creation and playback
//! - Multiple effect types
//! - Runtime capabilities checking
//!
//! Dependencies:
//! - Core SDL3 haptic functionality
//! - Joystick/gamepad for device access
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Open haptic device
//! const device = try haptic.openFromJoystick(joystick);
//! defer device.close();
//!
//! // Create and play a simple rumble effect
//! try device.rumblePlay(0.5, 1000);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Haptic device handle
pub const Device = struct {
    handle: *c.SDL_Haptic,

    /// Initialize a haptic device from a device index
    pub fn open(device_index: i32) !Device {
        const handle = c.SDL_HapticOpen(device_index) orelse return error.HapticOpenFailed;
        return Device{ .handle = handle };
    }

    /// Initialize a haptic device from a joystick
    pub fn openFromJoystick(joystick: *c.SDL_Joystick) !Device {
        const handle = c.SDL_HapticOpenFromJoystick(joystick) orelse return error.HapticOpenFailed;
        return Device{ .handle = handle };
    }

    /// Close a haptic device
    pub fn close(self: Device) void {
        c.SDL_HapticClose(self.handle);
    }

    /// Check if rumble is supported
    pub fn hasRumble(self: Device) bool {
        return c.SDL_HapticRumbleSupported(self.handle) == c.SDL_TRUE;
    }

    /// Initialize rumble support
    pub fn rumbleInit(self: Device) !void {
        if (!c.SDL_HapticRumbleInit(self.handle)) {
            return error.HapticRumbleInitFailed;
        }
    }

    /// Play a rumble effect
    pub fn rumblePlay(self: Device, strength: f32, duration_ms: u32) !void {
        if (!c.SDL_HapticRumblePlay(self.handle, strength, duration_ms)) {
            return error.HapticRumblePlayFailed;
        }
    }

    /// Stop the rumble effect
    pub fn rumbleStop(self: Device) !void {
        if (!c.SDL_HapticRumbleStop(self.handle)) {
            return error.HapticRumbleStopFailed;
        }
    }

    /// Get the number of haptic axes
    pub fn numAxes(self: Device) !i32 {
        const axes = c.SDL_HapticNumAxes(self.handle);
        if (axes < 0) return error.HapticNumAxesFailed;
        return axes;
    }

    /// Check if effect is supported
    pub fn effectSupported(self: Device, effect: *const c.SDL_HapticEffect) !bool {
        const supported = c.SDL_HapticEffectSupported(self.handle, effect);
        if (supported < 0) return error.HapticEffectSupportedFailed;
        return supported == 1;
    }

    /// Upload an effect to the device
    pub fn uploadEffect(self: Device, effect: *const c.SDL_HapticEffect) !i32 {
        const id = c.SDL_HapticNewEffect(self.handle, effect);
        if (id < 0) return error.HapticUploadEffectFailed;
        return id;
    }

    /// Run an effect
    pub fn runEffect(self: Device, effect_id: i32, iterations: u32) !void {
        if (!c.SDL_HapticRunEffect(self.handle, effect_id, iterations)) {
            return error.HapticRunEffectFailed;
        }
    }

    /// Stop an effect
    pub fn stopEffect(self: Device, effect_id: i32) !void {
        if (!c.SDL_HapticStopEffect(self.handle, effect_id)) {
            return error.HapticStopEffectFailed;
        }
    }

    /// Remove an effect from the device
    pub fn destroyEffect(self: Device, effect_id: i32) void {
        c.SDL_HapticDestroyEffect(self.handle, effect_id);
    }

    /// Pause a device
    pub fn pause(self: Device) !void {
        if (!c.SDL_HapticPause(self.handle)) {
            return error.HapticPauseFailed;
        }
    }

    /// Unpause a device
    pub fn unpause(self: Device) !void {
        if (!c.SDL_HapticUnpause(self.handle)) {
            return error.HapticUnpauseFailed;
        }
    }

    /// Stop all effects
    pub fn stopAll(self: Device) !void {
        if (!c.SDL_HapticStopAll(self.handle)) {
            return error.HapticStopAllFailed;
        }
    }
};

/// Get the number of haptic devices
pub fn numDevices() i32 {
    return c.SDL_NumHaptics();
}

/// Check if a joystick has haptic features
pub fn isJoystickHaptic(joystick: *c.SDL_Joystick) bool {
    return c.SDL_JoystickIsHaptic(joystick) == 1;
}

/// Get the implementation dependent name of a haptic device
pub fn deviceName(device_index: i32) ?[:0]const u8 {
    const name = c.SDL_HapticName(device_index) orelse return null;
    return std.mem.span(name);
}

test "haptic basics" {
    try core.init.init(.{ .haptic = true });
    defer core.init.quit();

    // Get number of haptic devices
    const num = numDevices();
    try std.testing.expect(num >= 0);

    // Skip test if no devices
    if (num == 0) return;

    // Open first device
    const device = try Device.open(0);
    defer device.close();

    // Get device info
    const axes = try device.numAxes();
    try std.testing.expect(axes >= 0);

    // Test rumble if supported
    if (device.hasRumble()) {
        try device.rumbleInit();
        try device.rumblePlay(0.5, 100);
        try device.rumbleStop();
    }
}
