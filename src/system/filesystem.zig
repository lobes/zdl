//! Filesystem functionality for SDL3.
//!
//! This module provides filesystem operations:
//! - Base path detection
//! - Preferences directory
//! - File operations
//!
//! Dependencies:
//! - Core SDL3 filesystem functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Get base paths
//! const base = try filesystem.getBasePath();
//! defer filesystem.freePath(base);
//! std.debug.print("Base path: {s}\n", .{base});
//!
//! const pref = try filesystem.getPrefPath("MyCompany", "MyApp");
//! defer filesystem.freePath(pref);
//! std.debug.print("Preferences path: {s}\n", .{pref});
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Get the directory where the application was run from
pub fn getBasePath() ![:0]const u8 {
    const path = c.SDL_GetBasePath() orelse return error.GetBasePathFailed;
    return std.mem.span(path);
}

/// Get the user-specific preferences directory
pub fn getPrefPath(org: [:0]const u8, app: [:0]const u8) ![:0]const u8 {
    const path = c.SDL_GetPrefPath(org.ptr, app.ptr) orelse return error.GetPrefPathFailed;
    return std.mem.span(path);
}

/// Free a path string returned by getBasePath() or getPrefPath()
pub fn freePath(path: [:0]const u8) void {
    c.SDL_free(@constCast(@ptrCast(path.ptr)));
}

test "filesystem basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get base path
    const base = try getBasePath();
    defer freePath(base);
    try std.testing.expect(base.len > 0);

    // Get preferences path
    const pref = try getPrefPath("ZDL3Test", "TestApp");
    defer freePath(pref);
    try std.testing.expect(pref.len > 0);
}
