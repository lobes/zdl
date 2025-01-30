//! SDL3 version information and feature checking.
//!
//! This module provides version information and feature checking:
//! - Runtime version checking
//! - Compile-time version constants
//! - Feature availability testing
//! - Version comparison utilities
//!
//! Dependencies:
//! - Core SDL3 version functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Check runtime version
//! const v = version.getVersion();
//! std.debug.print("SDL version: {d}.{d}.{d}\n", .{v.major, v.minor, v.patch});
//!
//! // Compare against compile-time version
//! if (version.compiledVersion().isAtLeast(3, 0, 0)) {
//!     // Use SDL3 features
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// SDL version information
pub const Version = extern struct {
    major: u8,
    minor: u8,
    patch: u8,

    /// Check if version is at least the specified version
    pub fn isAtLeast(self: Version, major: u8, minor: u8, patch: u8) bool {
        if (self.major != major) return self.major > major;
        if (self.minor != minor) return self.minor > minor;
        return self.patch >= patch;
    }

    /// Convert version to string
    pub fn toString(self: Version) [32]u8 {
        var buf: [32]u8 = undefined;
        _ = std.fmt.bufPrint(&buf, "{d}.{d}.{d}", .{
            self.major,
            self.minor,
            self.patch,
        }) catch return buf;
        return buf;
    }
};

/// Get the version of SDL that is linked against your program.
/// This same variable can be used to compare with SDL_COMPILEDVERSION
pub fn getVersion() Version {
    var v: Version = undefined;
    c.SDL_GetVersion(&v);
    return v;
}

/// Get the version of SDL that you compiled against
pub fn compiledVersion() Version {
    return .{
        .major = c.SDL_MAJOR_VERSION,
        .minor = c.SDL_MINOR_VERSION,
        .patch = c.SDL_PATCHLEVEL,
    };
}

/// Get the revision of SDL that is linked against your program
pub fn getRevision() [:0]const u8 {
    return std.mem.span(c.SDL_GetRevision());
}

/// Check whether the SDL library version matches the compile-time version
pub fn versionAtLeast(major: u8, minor: u8, patch: u8) bool {
    return getVersion().isAtLeast(major, minor, patch);
}

test "version information" {
    // Get runtime version
    const v = getVersion();
    try std.testing.expect(v.major >= 3);
    try std.testing.expect(v.isAtLeast(3, 0, 0));

    // Get compile time version
    const cv = compiledVersion();
    try std.testing.expect(cv.major >= 3);
    try std.testing.expect(cv.isAtLeast(3, 0, 0));

    // Get revision string
    const rev = getRevision();
    try std.testing.expect(rev.len > 0);
}

test "version comparison" {
    const v = Version{ .major = 3, .minor = 1, .patch = 0 };

    // Test exact version
    try std.testing.expect(v.isAtLeast(3, 1, 0));

    // Test older versions
    try std.testing.expect(v.isAtLeast(3, 0, 0));
    try std.testing.expect(v.isAtLeast(2, 9, 9));
    try std.testing.expect(v.isAtLeast(2, 0, 0));

    // Test newer versions
    try std.testing.expect(!v.isAtLeast(3, 1, 1));
    try std.testing.expect(!v.isAtLeast(3, 2, 0));
    try std.testing.expect(!v.isAtLeast(4, 0, 0));
}

test "version string" {
    const v = Version{ .major = 3, .minor = 1, .patch = 0 };
    const str = v.toString();
    try std.testing.expectEqualStrings("3.1.0", str[0..5]);
}
