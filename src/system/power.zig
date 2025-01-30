//! Power management functionality for SDL3.
//!
//! This module provides power management features:
//! - Battery status checking
//! - Power state monitoring
//! - Power management control
//!
//! Dependencies:
//! - Core SDL3 power functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Get power info
//! var secs: i32 = undefined;
//! var pct: i32 = undefined;
//! const state = power.getInfo(&secs, &pct);
//! if (state == .on_battery) {
//!     std.debug.print("Battery: {}%, {} seconds left\n", .{pct, secs});
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Power state
pub const PowerState = enum {
    unknown,
    on_battery,
    no_battery,
    charging,
    charged,
    err,

    fn fromSDL(state: c_int) PowerState {
        return switch (state) {
            c.SDL_POWERSTATE_UNKNOWN => .unknown,
            c.SDL_POWERSTATE_ON_BATTERY => .on_battery,
            c.SDL_POWERSTATE_NO_BATTERY => .no_battery,
            c.SDL_POWERSTATE_CHARGING => .charging,
            c.SDL_POWERSTATE_CHARGED => .charged,
            else => .err,
        };
    }
};

/// Get the current power supply state
pub fn getInfo(secs_left: ?*i32, pct_left: ?*i32) PowerState {
    var seconds: i32 = undefined;
    var percent: i32 = undefined;
    const state = c.SDL_GetPowerInfo(&seconds, &percent);

    if (secs_left) |s| s.* = seconds;
    if (pct_left) |p| p.* = percent;

    return PowerState.fromSDL(state);
}

test "power basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get power info
    var seconds: i32 = undefined;
    var percent: i32 = undefined;
    const state = getInfo(&seconds, &percent);

    // State should be valid
    try std.testing.expect(state != .err);

    // If we have a battery, values should be reasonable
    if (state == .on_battery or state == .charging or state == .charged) {
        try std.testing.expect(percent >= -1 and percent <= 100);
        try std.testing.expect(seconds >= -1);
    }
}
