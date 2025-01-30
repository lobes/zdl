//! Clipboard functionality for SDL3.
//!
//! This module provides clipboard operations:
//! - Text copying and pasting
//! - System clipboard access
//! - Clipboard change events
//!
//! Dependencies:
//! - Core SDL3 clipboard functionality
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Set clipboard text
//! try clipboard.setText("Hello, SDL3!");
//!
//! // Get clipboard text
//! if (clipboard.getText()) |text| {
//!     defer clipboard.freeText(text);
//!     std.debug.print("Clipboard: {s}\n", .{text});
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Set the clipboard text
pub fn setText(text: [:0]const u8) !void {
    if (!c.SDL_SetClipboardText(text.ptr)) {
        return error.SetClipboardTextFailed;
    }
}

/// Get the clipboard text
pub fn getText() ?[:0]const u8 {
    const text = c.SDL_GetClipboardText() orelse return null;
    return std.mem.span(text);
}

/// Free the text returned by getText()
pub fn freeText(text: [:0]const u8) void {
    c.SDL_free(@constCast(@ptrCast(text.ptr)));
}

/// Returns whether the clipboard exists and contains a text string that is non-empty
pub fn hasText() bool {
    return c.SDL_HasClipboardText() == c.SDL_TRUE;
}

test "clipboard basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Test setting clipboard text
    try setText("Test clipboard text");
    try std.testing.expect(hasText());

    // Test getting clipboard text
    if (getText()) |text| {
        defer freeText(text);
        try std.testing.expectEqualStrings("Test clipboard text", text);
    } else {
        try std.testing.expect(false); // Should have text
    }
}
