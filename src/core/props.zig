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

const core = @import("../core/module.zig");
const errors = core.errors;

/// A handle to a property group
pub const Properties = struct {
    id: c.SDL_PropertiesID,

    /// Create a new property group
    pub fn create() !Properties {
        const id = c.SDL_CreateProperties() orelse {
            return errors.sdlError();
        };
        return Properties{ .id = id };
    }

    /// Destroy a property group and free all associated resources
    pub fn destroy(self: *Properties) void {
        c.SDL_DestroyProperties(self.id);
        self.* = undefined;
    }

    /// Lock a property group for exclusive access
    pub fn lock(self: Properties) !void {
        if (!c.SDL_LockProperties(self.id)) {
            return errors.sdlError();
        }
    }

    /// Unlock a previously locked property group
    pub fn unlock(self: Properties) void {
        c.SDL_UnlockProperties(self.id);
    }

    /// Set a pointer property
    pub fn setPointer(self: Properties, name: [*:0]const u8, value: ?*anyopaque) !void {
        if (!c.SDL_SetPointerProperty(self.id, name, value)) {
            return errors.sdlError();
        }
    }

    /// Get a pointer property
    pub fn getPointer(self: Properties, name: [*:0]const u8) ?*anyopaque {
        return c.SDL_GetPointerProperty(self.id, name);
    }

    /// Set a string property
    pub fn setString(self: Properties, name: [*:0]const u8, value: [*:0]const u8) !void {
        if (!c.SDL_SetStringProperty(self.id, name, value)) {
            return errors.sdlError();
        }
    }

    /// Get a string property
    pub fn getString(self: Properties, name: [*:0]const u8) ?[*:0]const u8 {
        return c.SDL_GetStringProperty(self.id, name);
    }

    /// Set a number property
    pub fn setNumber(self: Properties, name: [*:0]const u8, value: i64) !void {
        if (!c.SDL_SetNumberProperty(self.id, name, value)) {
            return errors.sdlError();
        }
    }

    /// Get a number property
    pub fn getNumber(self: Properties, name: [*:0]const u8) i64 {
        return c.SDL_GetNumberProperty(self.id, name);
    }

    /// Set a float property
    pub fn setFloat(self: Properties, name: [*:0]const u8, value: f32) !void {
        if (!c.SDL_SetFloatProperty(self.id, name, value)) {
            return errors.sdlError();
        }
    }

    /// Get a float property
    pub fn getFloat(self: Properties, name: [*:0]const u8) f32 {
        return c.SDL_GetFloatProperty(self.id, name);
    }

    /// Set a boolean property
    pub fn setBoolean(self: Properties, name: [*:0]const u8, value: bool) !void {
        if (!c.SDL_SetBooleanProperty(self.id, name, value)) {
            return errors.sdlError();
        }
    }

    /// Get a boolean property
    pub fn getBoolean(self: Properties, name: [*:0]const u8) bool {
        return c.SDL_GetBooleanProperty(self.id, name);
    }

    /// Clear a property from the group
    pub fn clear(self: Properties, name: [*:0]const u8) void {
        c.SDL_ClearProperty(self.id, name);
    }

    /// Check if a property exists in the group
    pub fn has(self: Properties, name: [*:0]const u8) bool {
        return c.SDL_HasProperty(self.id, name);
    }
};

test "properties creation and destruction" {
    var props = try Properties.create();
    defer props.destroy();
}

test "property locking" {
    var props = try Properties.create();
    defer props.destroy();

    try props.lock();
    props.unlock();
}

test "string properties" {
    var props = try Properties.create();
    defer props.destroy();

    try props.setString("name", "test");
    const value = props.getString("name");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("test", std.mem.span(value.?));
}

test "number properties" {
    var props = try Properties.create();
    defer props.destroy();

    try props.setNumber("count", 42);
    const value = props.getNumber("count");
    try std.testing.expectEqual(@as(i64, 42), value);
}

test "float properties" {
    var props = try Properties.create();
    defer props.destroy();

    try props.setFloat("pi", 3.14159);
    const value = props.getFloat("pi");
    try std.testing.expectApproxEqAbs(@as(f32, 3.14159), value, 0.00001);
}

test "boolean properties" {
    var props = try Properties.create();
    defer props.destroy();

    try props.setBoolean("flag", true);
    const value = props.getBoolean("flag");
    try std.testing.expect(value);
}

test "pointer properties" {
    var props = try Properties.create();
    defer props.destroy();

    var data: i32 = 123;
    try props.setPointer("ptr", &data);
    const ptr = props.getPointer("ptr");
    try std.testing.expect(ptr != null);
    try std.testing.expectEqual(&data, @as(*i32, @ptrCast(@alignCast(ptr.?))));
}

test "property existence and clearing" {
    var props = try Properties.create();
    defer props.destroy();

    try props.setString("test", "value");
    try std.testing.expect(props.has("test"));

    props.clear("test");
    try std.testing.expect(!props.has("test"));
}
