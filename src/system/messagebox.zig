//! Message box functionality for SDL3.
//!
//! This module provides system message boxes:
//! - Simple message dialogs
//! - Custom button options
//! - Error display
//! - Color schemes
//!
//! Dependencies:
//! - Core SDL3 message box functionality
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Show a simple message box
//! try messagebox.show(.info, "Title", "Message", null);
//!
//! // Show a custom message box with buttons
//! var data = MessageBoxData{
//!     .flags = .warning,
//!     .window = null,
//!     .title = "Warning",
//!     .message = "Are you sure?",
//!     .buttons = &[_]MessageBoxButton{
//!         .{ .flags = .return_key, .text = "Yes" },
//!         .{ .flags = .escape_key, .text = "No" },
//!     },
//! };
//! const button_id = try messagebox.showCustom(&data);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Message box flags
pub const MessageBoxFlags = enum(u32) {
    error_ = c.SDL_MESSAGEBOX_ERROR,
    warning = c.SDL_MESSAGEBOX_WARNING,
    info = c.SDL_MESSAGEBOX_INFORMATION,
};

/// Message box button flags
pub const MessageBoxButtonFlags = enum(u32) {
    none = 0,
    return_key = c.SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT,
    escape_key = c.SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT,
};

/// Message box button data
pub const MessageBoxButton = struct {
    flags: MessageBoxButtonFlags = .none,
    button_id: i32 = 0,
    text: [:0]const u8,
};

/// Message box color type
pub const MessageBoxColorType = enum(u32) {
    background = c.SDL_MESSAGEBOX_COLOR_BACKGROUND,
    text = c.SDL_MESSAGEBOX_COLOR_TEXT,
    button_border = c.SDL_MESSAGEBOX_COLOR_BUTTON_BORDER,
    button_background = c.SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND,
    button_selected = c.SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED,
};

/// Message box color scheme
pub const MessageBoxColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

/// Message box color scheme data
pub const MessageBoxColorScheme = struct {
    colors: [5]MessageBoxColor,
};

/// Message box data
pub const MessageBoxData = struct {
    flags: MessageBoxFlags,
    window: ?*c.SDL_Window,
    title: [:0]const u8,
    message: [:0]const u8,
    buttons: []const MessageBoxButton,
    color_scheme: ?*const MessageBoxColorScheme = null,
};

/// Show a simple message box
pub fn show(flags: MessageBoxFlags, title: [:0]const u8, message: [:0]const u8, window: ?*c.SDL_Window) !void {
    if (!c.SDL_ShowSimpleMessageBox(@intFromEnum(flags), title.ptr, message.ptr, window)) {
        return error.ShowMessageBoxFailed;
    }
}

/// Show a custom message box
pub fn showCustom(data: *const MessageBoxData) !i32 {
    var button_id: i32 = undefined;
    var sdl_buttons = try std.heap.c_allocator.alloc(c.SDL_MessageBoxButtonData, data.buttons.len);
    defer std.heap.c_allocator.free(sdl_buttons);

    for (data.buttons, 0..) |button, i| {
        sdl_buttons[i] = .{
            .flags = @intFromEnum(button.flags),
            .buttonid = button.button_id,
            .text = button.text.ptr,
        };
    }

    var sdl_data = c.SDL_MessageBoxData{
        .flags = @intFromEnum(data.flags),
        .window = data.window,
        .title = data.title.ptr,
        .message = data.message.ptr,
        .numbuttons = @intCast(data.buttons.len),
        .buttons = sdl_buttons.ptr,
        .colorScheme = if (data.color_scheme) |scheme| @ptrCast(scheme) else null,
    };

    if (!c.SDL_ShowMessageBox(&sdl_data, &button_id)) {
        return error.ShowMessageBoxFailed;
    }

    return button_id;
}

test "messagebox basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Test simple message box (this will be skipped in automated testing)
    if (false) {
        try show(.info, "Test", "This is a test message", null);
    }

    // Test custom message box (this will be skipped in automated testing)
    if (false) {
        const buttons = [_]MessageBoxButton{
            .{
                .flags = .return_key,
                .button_id = 1,
                .text = "OK",
            },
            .{
                .flags = .escape_key,
                .button_id = 2,
                .text = "Cancel",
            },
        };

        const colors = MessageBoxColorScheme{
            .colors = [_]MessageBoxColor{
                .{ .r = 255, .g = 255, .b = 255 }, // background
                .{ .r = 0, .g = 0, .b = 0 }, // text
                .{ .r = 0, .g = 0, .b = 0 }, // button border
                .{ .r = 200, .g = 200, .b = 200 }, // button background
                .{ .r = 150, .g = 150, .b = 150 }, // button selected
            },
        };

        var data = MessageBoxData{
            .flags = .info,
            .window = null,
            .title = "Custom Test",
            .message = "This is a custom message box",
            .buttons = &buttons,
            .color_scheme = &colors,
        };

        const button_id = try showCustom(&data);
        try std.testing.expect(button_id == 1 or button_id == 2);
    }
}
