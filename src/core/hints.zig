//! Runtime configuration system for SDL3.
//!
//! This module provides a flexible hint system for configuring SDL behavior:
//! - Setting and getting configuration hints
//! - Priority levels for hint values
//! - Callback notifications for hint changes
//! - Thread-safe hint operations
//!
//! Dependencies:
//! - Core SDL3 hint system
//! - Uses error.zig for error handling
//!
//! Thread safety: All hint operations are thread-safe. Multiple threads can
//! safely read and write hints concurrently.
//!
//! Memory management: Hint values are managed by SDL. String values are copied
//! when set, and callbacks must be manually cleared when no longer needed.
//!
//! Example:
//! ```zig
//! // Set a hint with normal priority
//! try setHint("SDL_HINT_RENDER_VSYNC", "1");
//!
//! // Set a hint with override priority
//! try setHintWithPriority("SDL_HINT_RENDER_DRIVER", "metal", .override);
//!
//! // Get a hint value
//! if (getHint("SDL_HINT_RENDER_VSYNC")) |value| {
//!     // Use hint value...
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// Priority level for hints
pub const HintPriority = enum(c.SDL_HintPriority) {
    default = c.SDL_HINT_DEFAULT,
    normal = c.SDL_HINT_NORMAL,
    override = c.SDL_HINT_OVERRIDE,
};

/// Callback function type for hint changes
pub const HintCallback = fn (?*anyopaque, [*c]const u8, [*c]const u8, [*c]const u8) callconv(.C) void;

/// Set a hint with a specific priority
pub fn setHint(name: [:0]const u8, value: [:0]const u8) !void {
    if (!c.SDL_SetHint(name.ptr, value.ptr)) {
        return error.SDLError;
    }
}

/// Set a hint with specified priority
pub fn setHintWithPriority(
    name: [:0]const u8,
    value: [:0]const u8,
    priority: HintPriority,
) !void {
    if (!c.SDL_SetHintWithPriority(name.ptr, value.ptr, @intFromEnum(priority))) {
        return error.SDLError;
    }
}

/// Get the value of a hint
pub fn getHint(name: [:0]const u8) ?[:0]const u8 {
    const value = c.SDL_GetHint(name.ptr) orelse return null;
    return std.mem.span(value);
}

/// Reset all hints to their default values
pub fn resetHints() void {
    c.SDL_ResetHints();
}

/// Clear a specific hint
pub fn clearHint(name: [:0]const u8) void {
    setHint(name, "") catch {};
}

/// Add a function to watch a particular hint
pub fn addHintCallback(name: [:0]const u8, callback: HintCallback, data: ?*anyopaque) void {
    _ = c.SDL_AddHintCallback(name.ptr, callback, data);
}

/// Remove a function watching a particular hint
pub fn removeHintCallback(name: [:0]const u8, callback: HintCallback, data: ?*anyopaque) void {
    c.SDL_RemoveHintCallback(name.ptr, callback, data);
}

const TestContext = struct {
    triggered: *bool,

    pub fn onHintChanged(
        userdata: ?*anyopaque,
        _: [*c]const u8,
        _: [*c]const u8,
        _: [*c]const u8,
    ) callconv(.C) void {
        const self = @as(*TestContext, @ptrCast(@alignCast(userdata.?)));
        self.triggered.* = true;
    }
};

test "hint operations" {
    const sdl = @import("module.zig");
    try sdl.init(.{});
    defer sdl.quit();

    const test_hint = "SDL_TEST_HINT";
    const test_value = "test_value";

    // Test setting and getting hints
    try setHint(test_hint, test_value);
    const value = getHint(test_hint) orelse "";
    try std.testing.expectEqualStrings(test_value, value);

    // Test priority levels
    try setHintWithPriority(test_hint, "override_value", .override);
    const override_value = getHint(test_hint) orelse "";
    try std.testing.expectEqualStrings("override_value", override_value);

    // Test hint callback
    var callback_called = false;
    var context = TestContext{ .triggered = &callback_called };
    addHintCallback(test_hint, TestContext.onHintChanged, &context);
    try setHint(test_hint, "new_value");
    try std.testing.expect(callback_called);

    removeHintCallback(test_hint, TestContext.onHintChanged, &context);
    clearHint(test_hint);
}

test "hint reset" {
    // Set some test hints
    try setHint("SDL_TEST_HINT1", "value1");
    try setHint("SDL_TEST_HINT2", "value2");

    // Reset all hints
    resetHints();

    // Verify hints are cleared
    try std.testing.expect(getHint("SDL_TEST_HINT1") == null);
    try std.testing.expect(getHint("SDL_TEST_HINT2") == null);
}

test "hint priorities" {
    // Test priority override behavior
    try setHintWithPriority("SDL_TEST_HINT", "normal", .normal);
    try setHintWithPriority("SDL_TEST_HINT", "default", .default);
    const value1 = getHint("SDL_TEST_HINT") orelse "";
    try std.testing.expectEqualStrings("normal", value1);

    try setHintWithPriority("SDL_TEST_HINT", "override", .override);
    const value2 = getHint("SDL_TEST_HINT") orelse "";
    try std.testing.expectEqualStrings("override", value2);

    // Clean up
    clearHint("SDL_TEST_HINT");
}
