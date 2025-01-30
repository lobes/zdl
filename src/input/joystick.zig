//! Legacy joystick functionality for SDL3.
//!
//! This module provides joystick input handling:
//! - Device detection and enumeration
//! - Button and axis state reading
//! - Hat switch support
//! - Event handling
//!
//! Dependencies:
//! - Core SDL3 joystick functionality
//! - Events system for joystick events
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Open first available joystick
//! const joystick = try joystick.open(0);
//! defer joystick.close();
//!
//! // Read axis value
//! const axis_value = joystick.getAxis(0);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Hat positions
pub const hat = struct {
    pub const centered = c.SDL_HAT_CENTERED;
    pub const up = c.SDL_HAT_UP;
    pub const right = c.SDL_HAT_RIGHT;
    pub const down = c.SDL_HAT_DOWN;
    pub const left = c.SDL_HAT_LEFT;
    pub const rightup = c.SDL_HAT_RIGHTUP;
    pub const rightdown = c.SDL_HAT_RIGHTDOWN;
    pub const leftup = c.SDL_HAT_LEFTUP;
    pub const leftdown = c.SDL_HAT_LEFTDOWN;
};

/// Joystick power level
pub const PowerLevel = enum(i32) {
    unknown = c.SDL_JOYSTICK_POWER_UNKNOWN,
    empty = c.SDL_JOYSTICK_POWER_EMPTY,
    low = c.SDL_JOYSTICK_POWER_LOW,
    medium = c.SDL_JOYSTICK_POWER_MEDIUM,
    full = c.SDL_JOYSTICK_POWER_FULL,
    wired = c.SDL_JOYSTICK_POWER_WIRED,
    max = c.SDL_JOYSTICK_POWER_MAX,
};

/// Joystick device handle
pub const Joystick = struct {
    handle: *c.SDL_Joystick,

    /// Open a joystick for use
    pub fn open(device_index: i32) !Joystick {
        const handle = c.SDL_OpenJoystick(device_index) orelse return error.JoystickOpenFailed;
        return Joystick{ .handle = handle };
    }

    /// Close a joystick previously opened with open()
    pub fn close(self: Joystick) void {
        c.SDL_CloseJoystick(self.handle);
    }

    /// Get the number of general axis controls on a joystick
    pub fn numAxes(self: Joystick) i32 {
        return c.SDL_GetNumJoystickAxes(self.handle);
    }

    /// Get the number of buttons on a joystick
    pub fn numButtons(self: Joystick) i32 {
        return c.SDL_GetNumJoystickButtons(self.handle);
    }

    /// Get the number of POV hats on a joystick
    pub fn numHats(self: Joystick) i32 {
        return c.SDL_GetNumJoystickHats(self.handle);
    }

    /// Get the current state of an axis control on a joystick
    pub fn getAxis(self: Joystick, axis: i32) i16 {
        return c.SDL_GetJoystickAxis(self.handle, axis);
    }

    /// Get the current state of a button on a joystick
    pub fn getButton(self: Joystick, button: i32) bool {
        return c.SDL_GetJoystickButton(self.handle, button) == 1;
    }

    /// Get the current state of a POV hat on a joystick
    pub fn getHat(self: Joystick, hat_index: i32) u8 {
        return c.SDL_GetJoystickHat(self.handle, hat_index);
    }

    /// Get the battery level of a joystick
    pub fn getCurrentPowerLevel(self: Joystick) PowerLevel {
        return @enumFromInt(c.SDL_GetJoystickPowerLevel(self.handle));
    }

    /// Get the implementation dependent name of a joystick
    pub fn getName(self: Joystick) ?[:0]const u8 {
        const name = c.SDL_GetJoystickName(self.handle) orelse return null;
        return std.mem.span(name);
    }

    /// Get the player index of a joystick
    pub fn getPlayerIndex(self: Joystick) i32 {
        return c.SDL_GetJoystickPlayerIndex(self.handle);
    }

    /// Set the player index of a joystick
    pub fn setPlayerIndex(self: Joystick, player_index: i32) void {
        c.SDL_SetJoystickPlayerIndex(self.handle, player_index);
    }

    /// Get the implementation dependent GUID of a joystick
    pub fn getGUID(self: Joystick) [16]u8 {
        var guid: [16]u8 = undefined;
        const sdl_guid = c.SDL_GetJoystickGUID(self.handle);
        @memcpy(&guid, &sdl_guid.data);
        return guid;
    }

    /// Get the USB vendor ID of a joystick, if available
    pub fn getVendor(self: Joystick) u16 {
        return c.SDL_GetJoystickVendor(self.handle);
    }

    /// Get the USB product ID of a joystick, if available
    pub fn getProduct(self: Joystick) u16 {
        return c.SDL_GetJoystickProduct(self.handle);
    }

    /// Get the product version of a joystick, if available
    pub fn getProductVersion(self: Joystick) u16 {
        return c.SDL_GetJoystickProductVersion(self.handle);
    }

    /// Get the serial number of a joystick, if available
    pub fn getSerial(self: Joystick) ?[:0]const u8 {
        const serial = c.SDL_GetJoystickSerial(self.handle) orelse return null;
        return std.mem.span(serial);
    }

    /// Get the type of a joystick
    pub fn getType(self: Joystick) c.SDL_JoystickType {
        return c.SDL_GetJoystickType(self.handle);
    }

    /// Get the instance ID of a joystick
    pub fn getInstanceID(self: Joystick) i32 {
        return c.SDL_GetJoystickInstanceID(self.handle);
    }
};

/// Get the number of joysticks attached to the system
pub fn numJoysticks() i32 {
    return c.SDL_NumJoysticks();
}

/// Get information about a joystick
pub fn getJoystickInstanceName(device_index: i32) ?[:0]const u8 {
    const name = c.SDL_GetJoystickInstanceName(device_index) orelse return null;
    return std.mem.span(name);
}

/// Get the player index of a joystick
pub fn getJoystickInstancePlayerIndex(device_index: i32) i32 {
    return c.SDL_GetJoystickInstancePlayerIndex(device_index);
}

/// Get the implementation dependent GUID of a joystick
pub fn getJoystickInstanceGUID(device_index: i32) [16]u8 {
    var guid: [16]u8 = undefined;
    const sdl_guid = c.SDL_GetJoystickInstanceGUID(device_index);
    @memcpy(&guid, &sdl_guid.data);
    return guid;
}

/// Get the USB vendor ID of a joystick, if available
pub fn getJoystickInstanceVendor(device_index: i32) u16 {
    return c.SDL_GetJoystickInstanceVendor(device_index);
}

/// Get the USB product ID of a joystick, if available
pub fn getJoystickInstanceProduct(device_index: i32) u16 {
    return c.SDL_GetJoystickInstanceProduct(device_index);
}

/// Get the product version of a joystick, if available
pub fn getJoystickInstanceProductVersion(device_index: i32) u16 {
    return c.SDL_GetJoystickInstanceProductVersion(device_index);
}

/// Get the type of a joystick
pub fn getJoystickInstanceType(device_index: i32) c.SDL_JoystickType {
    return c.SDL_GetJoystickInstanceType(device_index);
}

/// Return true if the joystick has been opened and currently connected
pub fn isJoystickConnected(device_index: i32) bool {
    return c.SDL_IsJoystickConnected(device_index) == c.SDL_TRUE;
}

/// Update the current state of the open joysticks
pub fn update() void {
    c.SDL_UpdateJoysticks();
}

test "joystick basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get number of joysticks
    const num = numJoysticks();
    try std.testing.expect(num >= 0);

    // Skip test if no joysticks
    if (num == 0) return;

    // Get info about first joystick
    const name = getJoystickInstanceName(0);
    if (name) |n| try std.testing.expect(n.len > 0);

    const player_index = getJoystickInstancePlayerIndex(0);
    try std.testing.expect(player_index >= -1);

    const guid = getJoystickInstanceGUID(0);
    try std.testing.expect(guid.len == 16);

    const vendor = getJoystickInstanceVendor(0);
    _ = vendor; // May be 0 if not available

    const product = getJoystickInstanceProduct(0);
    _ = product; // May be 0 if not available

    const version = getJoystickInstanceProductVersion(0);
    _ = version; // May be 0 if not available

    const type_id = getJoystickInstanceType(0);
    try std.testing.expect(@intFromEnum(type_id) >= 0);

    // Open joystick
    const joystick = try Joystick.open(0);
    defer joystick.close();

    // Get joystick info
    const num_axes = joystick.numAxes();
    try std.testing.expect(num_axes >= 0);

    const num_buttons = joystick.numButtons();
    try std.testing.expect(num_buttons >= 0);

    const num_hats = joystick.numHats();
    try std.testing.expect(num_hats >= 0);

    // Read state if controls exist
    if (num_axes > 0) {
        const axis = joystick.getAxis(0);
        try std.testing.expect(axis >= -32768 and axis <= 32767);
    }

    if (num_buttons > 0) {
        const button = joystick.getButton(0);
        try std.testing.expect(button == false or button == true);
    }

    if (num_hats > 0) {
        const hat_state = joystick.getHat(0);
        try std.testing.expect(hat_state <= 0x0F);
    }

    // Get power level
    const power = joystick.getCurrentPowerLevel();
    try std.testing.expect(@intFromEnum(power) >= 0);
}
