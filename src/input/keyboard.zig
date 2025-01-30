//! Keyboard functionality for SDL3.
//!
//! This module provides keyboard input handling:
//! - Key state tracking
//! - Text input handling
//! - Key mapping and translation
//! - Keyboard layout support
//!
//! Dependencies:
//! - Core SDL3 keyboard functionality
//! - Events system for key events
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Get keyboard state
//! const state = keyboard.getState();
//! if (state[keyboard.scancode.space]) {
//!     // Space is pressed
//! }
//!
//! // Enable text input
//! keyboard.startTextInput();
//! defer keyboard.stopTextInput();
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Keyboard scancodes - physical key positions
pub const Scancode = enum(i32) {
    unknown = c.SDL_SCANCODE_UNKNOWN,
    a = c.SDL_SCANCODE_A,
    b = c.SDL_SCANCODE_B,
    c = c.SDL_SCANCODE_C,
    d = c.SDL_SCANCODE_D,
    e = c.SDL_SCANCODE_E,
    f = c.SDL_SCANCODE_F,
    g = c.SDL_SCANCODE_G,
    h = c.SDL_SCANCODE_H,
    i = c.SDL_SCANCODE_I,
    j = c.SDL_SCANCODE_J,
    k = c.SDL_SCANCODE_K,
    l = c.SDL_SCANCODE_L,
    m = c.SDL_SCANCODE_M,
    n = c.SDL_SCANCODE_N,
    o = c.SDL_SCANCODE_O,
    p = c.SDL_SCANCODE_P,
    q = c.SDL_SCANCODE_Q,
    r = c.SDL_SCANCODE_R,
    s = c.SDL_SCANCODE_S,
    t = c.SDL_SCANCODE_T,
    u = c.SDL_SCANCODE_U,
    v = c.SDL_SCANCODE_V,
    w = c.SDL_SCANCODE_W,
    x = c.SDL_SCANCODE_X,
    y = c.SDL_SCANCODE_Y,
    z = c.SDL_SCANCODE_Z,

    num1 = c.SDL_SCANCODE_1,
    num2 = c.SDL_SCANCODE_2,
    num3 = c.SDL_SCANCODE_3,
    num4 = c.SDL_SCANCODE_4,
    num5 = c.SDL_SCANCODE_5,
    num6 = c.SDL_SCANCODE_6,
    num7 = c.SDL_SCANCODE_7,
    num8 = c.SDL_SCANCODE_8,
    num9 = c.SDL_SCANCODE_9,
    num0 = c.SDL_SCANCODE_0,

    @"return" = c.SDL_SCANCODE_RETURN,
    escape = c.SDL_SCANCODE_ESCAPE,
    backspace = c.SDL_SCANCODE_BACKSPACE,
    tab = c.SDL_SCANCODE_TAB,
    space = c.SDL_SCANCODE_SPACE,

    minus = c.SDL_SCANCODE_MINUS,
    equals = c.SDL_SCANCODE_EQUALS,
    leftbracket = c.SDL_SCANCODE_LEFTBRACKET,
    rightbracket = c.SDL_SCANCODE_RIGHTBRACKET,
    backslash = c.SDL_SCANCODE_BACKSLASH,
    semicolon = c.SDL_SCANCODE_SEMICOLON,
    apostrophe = c.SDL_SCANCODE_APOSTROPHE,
    grave = c.SDL_SCANCODE_GRAVE,
    comma = c.SDL_SCANCODE_COMMA,
    period = c.SDL_SCANCODE_PERIOD,
    slash = c.SDL_SCANCODE_SLASH,
    capslock = c.SDL_SCANCODE_CAPSLOCK,

    f1 = c.SDL_SCANCODE_F1,
    f2 = c.SDL_SCANCODE_F2,
    f3 = c.SDL_SCANCODE_F3,
    f4 = c.SDL_SCANCODE_F4,
    f5 = c.SDL_SCANCODE_F5,
    f6 = c.SDL_SCANCODE_F6,
    f7 = c.SDL_SCANCODE_F7,
    f8 = c.SDL_SCANCODE_F8,
    f9 = c.SDL_SCANCODE_F9,
    f10 = c.SDL_SCANCODE_F10,
    f11 = c.SDL_SCANCODE_F11,
    f12 = c.SDL_SCANCODE_F12,

    printscreen = c.SDL_SCANCODE_PRINTSCREEN,
    scrolllock = c.SDL_SCANCODE_SCROLLLOCK,
    pause = c.SDL_SCANCODE_PAUSE,
    insert = c.SDL_SCANCODE_INSERT,
    home = c.SDL_SCANCODE_HOME,
    pageup = c.SDL_SCANCODE_PAGEUP,
    delete = c.SDL_SCANCODE_DELETE,
    end = c.SDL_SCANCODE_END,
    pagedown = c.SDL_SCANCODE_PAGEDOWN,
    right = c.SDL_SCANCODE_RIGHT,
    left = c.SDL_SCANCODE_LEFT,
    down = c.SDL_SCANCODE_DOWN,
    up = c.SDL_SCANCODE_UP,

    numlockclear = c.SDL_SCANCODE_NUMLOCKCLEAR,
    kp_divide = c.SDL_SCANCODE_KP_DIVIDE,
    kp_multiply = c.SDL_SCANCODE_KP_MULTIPLY,
    kp_minus = c.SDL_SCANCODE_KP_MINUS,
    kp_plus = c.SDL_SCANCODE_KP_PLUS,
    kp_enter = c.SDL_SCANCODE_KP_ENTER,
    kp_1 = c.SDL_SCANCODE_KP_1,
    kp_2 = c.SDL_SCANCODE_KP_2,
    kp_3 = c.SDL_SCANCODE_KP_3,
    kp_4 = c.SDL_SCANCODE_KP_4,
    kp_5 = c.SDL_SCANCODE_KP_5,
    kp_6 = c.SDL_SCANCODE_KP_6,
    kp_7 = c.SDL_SCANCODE_KP_7,
    kp_8 = c.SDL_SCANCODE_KP_8,
    kp_9 = c.SDL_SCANCODE_KP_9,
    kp_0 = c.SDL_SCANCODE_KP_0,
    kp_period = c.SDL_SCANCODE_KP_PERIOD,

    lctrl = c.SDL_SCANCODE_LCTRL,
    lshift = c.SDL_SCANCODE_LSHIFT,
    lalt = c.SDL_SCANCODE_LALT,
    lgui = c.SDL_SCANCODE_LGUI,
    rctrl = c.SDL_SCANCODE_RCTRL,
    rshift = c.SDL_SCANCODE_RSHIFT,
    ralt = c.SDL_SCANCODE_RALT,
    rgui = c.SDL_SCANCODE_RGUI,
};

/// Get a snapshot of the current keyboard state
pub fn getState() []const bool {
    var num_keys: c_int = undefined;
    const state = c.SDL_GetKeyboardState(&num_keys);
    return @as([*]const bool, @ptrCast(state))[0..@intCast(num_keys)];
}

/// Get the current key modifier state
pub fn getModState() u16 {
    return c.SDL_GetModState();
}

/// Set the current key modifier state
pub fn setModState(modstate: u16) void {
    c.SDL_SetModState(modstate);
}

/// Start accepting Unicode text input events
pub fn startTextInput() void {
    c.SDL_StartTextInput();
}

/// Stop receiving any text input events
pub fn stopTextInput() void {
    c.SDL_StopTextInput();
}

/// Returns whether or not Unicode text input events are enabled
pub fn isTextInputActive() bool {
    return c.SDL_IsTextInputActive() == c.SDL_TRUE;
}

/// Set the rectangle used to type Unicode text inputs
pub fn setTextInputRect(rect: ?*const c.SDL_Rect) void {
    c.SDL_SetTextInputRect(rect);
}

/// Check whether the platform has screen keyboard support
pub fn hasScreenKeyboardSupport() bool {
    return c.SDL_HasScreenKeyboardSupport() == c.SDL_TRUE;
}

/// Check whether the screen keyboard is shown for given window
pub fn isScreenKeyboardShown(window: *c.SDL_Window) bool {
    return c.SDL_IsScreenKeyboardShown(window) == c.SDL_TRUE;
}

test "keyboard basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get keyboard state
    const state = getState();
    try std.testing.expect(state.len > 0);

    // Test mod state
    setModState(c.SDL_KMOD_NONE);
    const mods = getModState();
    try std.testing.expectEqual(@as(u16, c.SDL_KMOD_NONE), mods);

    // Test text input
    startTextInput();
    try std.testing.expect(isTextInputActive());
    stopTextInput();
    try std.testing.expect(!isTextInputActive());

    // Test screen keyboard support
    _ = hasScreenKeyboardSupport();
}
