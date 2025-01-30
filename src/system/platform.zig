//! Platform functionality for SDL3.
//!
//! This module provides platform-specific information:
//! - Platform detection
//! - System information
//! - Platform-specific features
//!
//! Dependencies:
//! - Core SDL3 platform functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Get platform info
//! const platform_name = platform.getName();
//! std.debug.print("Running on: {s}\n", .{platform_name});
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Get the name of the platform
pub fn getName() [:0]const u8 {
    return std.mem.span(c.SDL_GetPlatform());
}

/// Get the number of CPU cores available
pub fn getCPUCount() i32 {
    return c.SDL_GetCPUCount();
}

/// Get the amount of RAM configured in the system
pub fn getSystemRAM() i32 {
    return c.SDL_GetSystemRAM();
}

/// Get the preferred language
pub fn getPreferredLocales() ?[:0]const u8 {
    const locales = c.SDL_GetPreferredLocales() orelse return null;
    return std.mem.span(locales);
}

test "platform basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get platform name
    const name = getName();
    try std.testing.expect(name.len > 0);

    // Get CPU count
    const cpu_count = getCPUCount();
    try std.testing.expect(cpu_count > 0);

    // Get system RAM
    const ram = getSystemRAM();
    try std.testing.expect(ram > 0);

    // Get preferred locales
    if (getPreferredLocales()) |locales| {
        try std.testing.expect(locales.len > 0);
    }
}
