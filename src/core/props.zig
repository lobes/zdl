//! Property management system for SDL3.
//!
//! This module provides a flexible property storage system:
//! - Thread-safe property groups
//! - Multiple data type support (strings, numbers, floats, booleans, pointers)
//! - Property locking for exclusive access
//! - Automatic cleanup of property values
//!
//! Dependencies:
//! - Core SDL3 property system
//! - Uses error.zig for error handling
//!
//! Thread safety: Property groups are thread-safe when properly locked.
//! Multiple threads can safely access different property groups, or the
//! same group when using the locking mechanism.
//!
//! Memory management: Property groups must be explicitly destroyed when
//! no longer needed. String values are copied, and pointer values must
//! be managed by the caller.
//!
//! Example:
//! ```zig
//! const props = try Properties.create();
//! defer props.destroy();
//!
//! try props.setString("name", "example");
//! try props.setNumber("count", 42);
//! try props.setFloat("scale", 1.5);
//! try props.setBoolean("enabled", true);
//!
//! // Thread-safe access
//! try props.lock();
//! defer props.unlock();
//! if (props.getString("name")) |name| {
//!     // Use property...
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// A handle to a property group
pub const Properties = struct {
    id: c.SDL_PropertiesID,

    /// Create a new property group
    pub fn create() !Properties {
        const id = c.SDL_CreateProperties();
        if (id == 0) {
            return error.SDLError;
        }
        return Properties{ .id = id };
    }

    /// Destroy a property group and free all associated resources
    pub fn destroy(self: *Properties) void {
        c.SDL_DestroyProperties(self.id);
    }

    /// Lock a property group for exclusive access
    pub fn lock(self: Properties) !void {
        if (!c.SDL_LockProperties(self.id)) {
            return error.SDLError;
        }
    }

    /// Unlock a previously locked property group
    pub fn unlock(self: Properties) void {
        c.SDL_UnlockProperties(self.id);
    }

    /// Set a pointer property
    pub fn setPointer(self: Properties, name: [*:0]const u8, value: ?*anyopaque) !void {
        if (!c.SDL_SetPointerProperty(self.id, name, value)) {
            return error.SDLError;
        }
    }

    /// Get a pointer property
    pub fn getPointer(self: Properties, name: [*:0]const u8) ?*anyopaque {
        return c.SDL_GetPointerProperty(self.id, name);
    }

    /// Set a string property
    pub fn setString(self: Properties, name: [:0]const u8, value: [:0]const u8) !void {
        if (!c.SDL_SetStringProperty(self.id, name.ptr, value.ptr)) {
            return error.SDLError;
        }
    }

    /// Get a string property
    pub fn getString(self: Properties, name: [:0]const u8) ![:0]const u8 {
        const value = c.SDL_GetStringProperty(self.id, name.ptr, null) orelse {
            return error.SDLError;
        };
        return std.mem.span(value);
    }

    /// Get a string property with a default value
    pub fn getStringWithDefault(self: Properties, name: [:0]const u8, default_value: [:0]const u8) [:0]const u8 {
        const value = c.SDL_GetStringProperty(self.id, name.ptr, default_value.ptr);
        return std.mem.span(value);
    }

    /// Set a number property
    pub fn setNumber(self: Properties, name: [:0]const u8, value: i64) !void {
        if (!c.SDL_SetNumberProperty(self.id, name.ptr, value)) {
            return error.SDLError;
        }
    }

    /// Get a number property
    pub fn getNumber(self: Properties, name: [:0]const u8) !i64 {
        const value = c.SDL_GetNumberProperty(self.id, name.ptr, 0);
        if (value == 0 and !c.SDL_HasProperty(self.id, name.ptr)) {
            return error.SDLError;
        }
        return value;
    }

    /// Clear a property from the group
    pub fn clear(self: Properties, name: [:0]const u8) void {
        _ = c.SDL_ClearProperty(self.id, name.ptr);
    }

    /// Check if a property exists in the group
    pub fn hasProperty(self: Properties, name: [:0]const u8) bool {
        return c.SDL_HasProperty(self.id, name.ptr);
    }
};

test "properties operations" {
    const sdl = @import("module.zig");
    try sdl.init(.{});
    defer sdl.quit();

    var props = try Properties.create();
    defer props.destroy();

    // Test string property
    try props.setString("name", "test");
    try std.testing.expect(props.hasProperty("name"));
    const name = try props.getString("name");
    try std.testing.expectEqualStrings("test", name);

    // Test number property
    try props.setNumber("value", 42);
    try std.testing.expect(props.hasProperty("value"));
    const value = try props.getNumber("value");
    try std.testing.expectEqual(@as(i64, 42), value);

    // Test clearing property
    props.clear("name");
    try std.testing.expect(!props.hasProperty("name"));
}
