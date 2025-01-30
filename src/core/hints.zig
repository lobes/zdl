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

const core = @import("../core/module.zig");
const errors = core.errors;

/// Priority level for hints
pub const HintPriority = enum(c.SDL_HintPriority) {
    default = c.SDL_HINT_DEFAULT,
    normal = c.SDL_HINT_NORMAL,
    override = c.SDL_HINT_OVERRIDE,
};

/// Callback function type for hint changes
pub const HintCallback = *const fn (
    userdata: ?*anyopaque,
    name: [*:0]const u8,
    oldValue: [*:0]const u8,
    newValue: [*:0]const u8,
) void;

/// Set a hint with normal priority
pub fn setHint(name: [*:0]const u8, value: [*:0]const u8) !void {
    if (!c.SDL_SetHint(name, value)) {
        return errors.sdlError();
    }
}

/// Set a hint with specified priority
pub fn setHintWithPriority(
    name: [*:0]const u8,
    value: [*:0]const u8,
    priority: HintPriority,
) !void {
    if (!c.SDL_SetHintWithPriority(name, value, @intFromEnum(priority))) {
        return errors.sdlError();
    }
}

/// Get the value of a hint
pub fn getHint(name: [*:0]const u8) ?[*:0]const u8 {
    return c.SDL_GetHint(name);
}

/// Reset all hints to their default values
pub fn resetHints() void {
    c.SDL_ResetHints();
}

/// Clear a specific hint
pub fn clearHint(name: [*:0]const u8) void {
    c.SDL_ClearHint(name);
}

/// Add a callback to be triggered when a hint changes
pub fn addHintCallback(
    name: [*:0]const u8,
    callback: HintCallback,
    userdata: ?*anyopaque,
) void {
    c.SDL_AddHintCallback(
        name,
        @ptrCast(callback),
        userdata,
    );
}

/// Remove a previously-added callback
pub fn delHintCallback(
    name: [*:0]const u8,
    callback: HintCallback,
    userdata: ?*anyopaque,
) void {
    c.SDL_DelHintCallback(
        name,
        @ptrCast(callback),
        userdata,
    );
}

const TestContext = struct {
    triggered: *bool,

    pub fn onHintChanged(
        userdata: ?*anyopaque,
        _: [*:0]const u8,
        _: [*:0]const u8,
        _: [*:0]const u8,
    ) void {
        const self = @as(*TestContext, @ptrCast(@alignCast(userdata.?)));
        self.triggered.* = true;
    }
};

test "hint operations" {
    // Test setting and getting hints
    try setHint("SDL_TEST_HINT", "test_value");
    const value = getHint("SDL_TEST_HINT");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("test_value", std.mem.span(value.?));

    // Test priority levels
    try setHintWithPriority("SDL_TEST_HINT", "override_value", .override);
    const override_value = getHint("SDL_TEST_HINT");
    try std.testing.expect(override_value != null);
    try std.testing.expectEqualStrings("override_value", std.mem.span(override_value.?));

    // Test hint callback
    var callback_triggered = false;
    var context = TestContext{ .triggered = &callback_triggered };
    addHintCallback(
        "SDL_TEST_HINT",
        TestContext.onHintChanged,
        &context,
    );

    try setHint("SDL_TEST_HINT", "new_value");
    try std.testing.expect(callback_triggered);

    // Clean up
    delHintCallback(
        "SDL_TEST_HINT",
        TestContext.onHintChanged,
        &context,
    );
    clearHint("SDL_TEST_HINT");
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
    const value1 = getHint("SDL_TEST_HINT");
    try std.testing.expect(value1 != null);
    try std.testing.expectEqualStrings("normal", std.mem.span(value1.?));

    try setHintWithPriority("SDL_TEST_HINT", "override", .override);
    const value2 = getHint("SDL_TEST_HINT");
    try std.testing.expect(value2 != null);
    try std.testing.expectEqualStrings("override", std.mem.span(value2.?));

    // Clean up
    clearHint("SDL_TEST_HINT");
}
