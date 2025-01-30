//! Mouse functionality for SDL3.
//!
//! This module provides mouse input handling:
//! - Button state tracking
//! - Cursor control
//! - Relative motion
//! - Mouse capture
//!
//! Dependencies:
//! - Core SDL3 mouse functionality
//! - Events system for mouse events
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Get mouse state
//! var x: i32 = undefined;
//! var y: i32 = undefined;
//! const buttons = mouse.getGlobalState(&x, &y);
//! if (buttons & @as(u32, mouse.button.left) != 0) {
//!     // Left button is pressed
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Mouse button masks
pub const button = struct {
    pub const left = c.SDL_BUTTON_LMASK;
    pub const middle = c.SDL_BUTTON_MMASK;
    pub const right = c.SDL_BUTTON_RMASK;
    pub const x1 = c.SDL_BUTTON_X1MASK;
    pub const x2 = c.SDL_BUTTON_X2MASK;
};

/// System cursor types
pub const SystemCursor = enum(i32) {
    arrow = c.SDL_SYSTEM_CURSOR_ARROW,
    ibeam = c.SDL_SYSTEM_CURSOR_IBEAM,
    wait = c.SDL_SYSTEM_CURSOR_WAIT,
    crosshair = c.SDL_SYSTEM_CURSOR_CROSSHAIR,
    waitarrow = c.SDL_SYSTEM_CURSOR_WAITARROW,
    sizenwse = c.SDL_SYSTEM_CURSOR_SIZENWSE,
    sizenesw = c.SDL_SYSTEM_CURSOR_SIZENESW,
    sizewe = c.SDL_SYSTEM_CURSOR_SIZEWE,
    sizens = c.SDL_SYSTEM_CURSOR_SIZENS,
    sizeall = c.SDL_SYSTEM_CURSOR_SIZEALL,
    no = c.SDL_SYSTEM_CURSOR_NO,
    hand = c.SDL_SYSTEM_CURSOR_HAND,
};

/// Mouse cursor handle
pub const Cursor = struct {
    handle: *c.SDL_Cursor,

    /// Create a system cursor
    pub fn createSystem(id: SystemCursor) !Cursor {
        const handle = c.SDL_CreateSystemCursor(@intFromEnum(id)) orelse return error.CreateSystemCursorFailed;
        return Cursor{ .handle = handle };
    }

    /// Destroy a cursor
    pub fn destroy(self: Cursor) void {
        c.SDL_DestroyCursor(self.handle);
    }
};

/// Get the current state of the mouse
pub fn getGlobalState(x: *i32, y: *i32) u32 {
    return c.SDL_GetGlobalMouseState(x, y);
}

/// Get the current state of the mouse relative to a window
pub fn getState(window: *c.SDL_Window, x: *f32, y: *f32) u32 {
    return c.SDL_GetMouseState(window, x, y);
}

/// Get the current state of the mouse in relative mode
pub fn getRelativeState(window: *c.SDL_Window, x: *f32, y: *f32) u32 {
    return c.SDL_GetRelativeMouseState(window, x, y);
}

/// Warp the mouse to a position in global screen space
pub fn warpGlobal(x: i32, y: i32) !void {
    if (!c.SDL_WarpMouseGlobal(x, y)) {
        return error.WarpMouseGlobalFailed;
    }
}

/// Warp the mouse to a position in window space
pub fn warp(window: *c.SDL_Window, x: f32, y: f32) !void {
    if (!c.SDL_WarpMouseInWindow(window, x, y)) {
        return error.WarpMouseInWindowFailed;
    }
}

/// Set relative mouse mode
pub fn setRelativeMode(enabled: bool) !void {
    if (!c.SDL_SetRelativeMouseMode(if (enabled) c.SDL_TRUE else c.SDL_FALSE)) {
        return error.SetRelativeMouseModeFailed;
    }
}

/// Get the current relative mouse mode
pub fn getRelativeMode() bool {
    return c.SDL_GetRelativeMouseMode() == c.SDL_TRUE;
}

/// Show the cursor
pub fn show() !void {
    if (c.SDL_ShowCursor() < 0) {
        return error.ShowCursorFailed;
    }
}

/// Hide the cursor
pub fn hide() !void {
    if (c.SDL_HideCursor() < 0) {
        return error.HideCursorFailed;
    }
}

/// Set the active cursor
pub fn setCursor(cur: ?Cursor) void {
    c.SDL_SetCursor(if (cur) |cursor| cursor.handle else null);
}

/// Get the active cursor
pub fn getCursor() ?Cursor {
    const handle = c.SDL_GetCursor();
    return if (handle != null) Cursor{ .handle = handle } else null;
}

/// Get the default cursor
pub fn getDefaultCursor() ?Cursor {
    const handle = c.SDL_GetDefaultCursor();
    return if (handle != null) Cursor{ .handle = handle } else null;
}

/// Capture the mouse in a window
pub fn capture(window: ?*c.SDL_Window) !void {
    if (!c.SDL_CaptureMouse(if (window != null) c.SDL_TRUE else c.SDL_FALSE)) {
        return error.CaptureMouseFailed;
    }
}

test "mouse basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get mouse state
    var x: i32 = undefined;
    var y: i32 = undefined;
    const buttons = getGlobalState(&x, &y);
    try std.testing.expect(buttons >= 0);

    // Test relative mode
    try setRelativeMode(true);
    try std.testing.expect(getRelativeMode());
    try setRelativeMode(false);
    try std.testing.expect(!getRelativeMode());

    // Test cursor visibility
    try show();
    try hide();
    try show();

    // Test system cursor
    const cursor = try Cursor.createSystem(.arrow);
    defer cursor.destroy();

    setCursor(cursor);
    const active = getCursor();
    try std.testing.expect(active != null);

    const default = getDefaultCursor();
    try std.testing.expect(default != null);
}
