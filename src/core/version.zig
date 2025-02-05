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
const root = @import("../../zdl.zig");
const c = root.c;

/// Get the version of SDL that is linked against your program
pub fn getVersion() Version {
    const ver_int = c.SDL_GetVersion();
    return Version{
        .major = @intCast((ver_int >> 16) & 0xFF),
        .minor = @intCast((ver_int >> 8) & 0xFF),
        .patch = @intCast(ver_int & 0xFF),
    };
}

/// Get the version of SDL that your program is compiled against
pub fn getCompiledVersion() Version {
    return Version{
        .major = c.SDL_MAJOR_VERSION,
        .minor = c.SDL_MINOR_VERSION,
        .patch = c.SDL_MICRO_VERSION,
    };
}

/// Get the revision number of SDL that is linked against your program
pub fn getRevision() [:0]const u8 {
    return std.mem.span(c.SDL_GetRevision());
}

/// Get the revision number of SDL that your program is compiled against
pub fn getCompiledRevision() [:0]const u8 {
    return std.mem.span(c.SDL_GetRevision()); // SDL3 doesn't have SDL_REVISION anymore
}

/// Version structure
pub const Version = struct {
    major: u8,
    minor: u8,
    patch: u8,

    /// Convert to string
    pub fn toString(self: Version) [32:0]u8 {
        var buf: [32:0]u8 = [_:0]u8{0} ** 32;
        _ = std.fmt.bufPrintZ(&buf, "{d}.{d}.{d}", .{
            self.major,
            self.minor,
            self.patch,
        }) catch unreachable;
        return buf;
    }
};

test "version info" {
    const ver = getVersion();
    const compiled = getCompiledVersion();
    const rev = getRevision();
    const compiled_rev = getCompiledRevision();

    try std.testing.expect(ver.major >= 3);
    try std.testing.expect(compiled.major >= 3);
    try std.testing.expect(rev.len > 0);
    try std.testing.expect(compiled_rev.len > 0);
}

test "version string" {
    const ver = Version{ .major = 3, .minor = 0, .patch = 0 };
    const str = ver.toString();
    const expected = "3.0.0";
    try std.testing.expectEqualStrings(expected, str[0..expected.len]);
}
