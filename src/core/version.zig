//! Version information for SDL3.
//!
//! This module provides functions to query SDL version information:
//! - Runtime version information
//! - Compile-time version information
//! - Version comparison utilities
//!
//! Example:
//! ```zig
//! const version = sdl.version.getVersion();
//! std.debug.print("SDL Version: {d}.{d}.{d}\n", .{
//!     version.major,
//!     version.minor,
//!     version.patch,
//! });
//! ```

const std = @import("std");
const c = @import("../c.zig");

/// SDL version information
pub const Version = struct {
    pub fn compiled() c_int {
        return c.SDL_VERSION;
    }

    pub fn linked() c_int {
        return c.SDL_GetVersion();
    }

    pub fn revision() []const u8 {
        return std.mem.span(c.SDL_GetRevision());
    }

    pub fn major(version: c_int) c_int {
        return c.SDL_VERSIONNUM_MAJOR(version);
    }

    pub fn minor(version: c_int) c_int {
        return c.SDL_VERSIONNUM_MINOR(version);
    }

    pub fn micro(version: c_int) c_int {
        return c.SDL_VERSIONNUM_MICRO(version);
    }

    pub fn isAtLeast(version: c_int, x: c_int, y: c_int, z: c_int) bool {
        return version >= c.SDL_VERSIONNUM(x, y, z);
    }
};

test "version" {
    const ver = Version.linked();
    try std.testing.expect(ver > 0);

    const rev = Version.revision();
    try std.testing.expect(rev.len > 0);

    // Test version number extraction
    const test_ver = c.SDL_VERSIONNUM(3, 2, 1);
    try std.testing.expectEqual(Version.major(test_ver), 3);
    try std.testing.expectEqual(Version.minor(test_ver), 2);
    try std.testing.expectEqual(Version.micro(test_ver), 1);

    // Test version comparison
    try std.testing.expect(Version.isAtLeast(test_ver, 3, 2, 0));
    try std.testing.expect(!Version.isAtLeast(test_ver, 3, 2, 2));
}
