//! Event handling and processing for SDL3.
//!
//! This module provides a type-safe wrapper around SDL's event system:
//! - Event polling and waiting
//! - Keyboard and mouse events
//! - Window events
//! - Text input events
//! - Event filtering and processing
//!
//! Dependencies:
//! - Core SDL3 event system
//! - Requires SDL_INIT_EVENTS subsystem
//!
//! Thread safety: SDL's event queue is thread-safe for basic operations.
//! Multiple threads can safely push events, but event polling should
//! typically be done from a single thread.
//!
//! Platform notes:
//! - Text input handling varies by platform and input method
//! - Some key codes may be platform-specific
//! - Touch events may not be available on all platforms
//!
//! Example:
//! ```zig
//! while (true) {
//!     if (pollEvent()) |event| {
//!         switch (event) {
//!             .quit => break,
//!             .key_down => |key| {
//!                 if (key.keycode == .escape) break;
//!             },
//!             .window => |win| {
//!                 if (win.event == .resized) {
//!                     // Handle resize...
//!                 }
//!             },
//!             else => {},
//!         }
//!     }
//! }
//! ```

const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");

pub const Event = union(enum) {
    quit,
    key_down: KeyEvent,
    key_up: KeyEvent,
    mouse_motion: MouseMotionEvent,
    mouse_button_down: MouseButtonEvent,
    mouse_button_up: MouseButtonEvent,
    window: WindowEvent,
    text_input: TextInputEvent,
    unknown,

    pub fn from(sdl_event: c.SDL_Event) Event {
        return switch (sdl_event.type) {
            c.SDL_EVENT_QUIT => Event.quit,
            c.SDL_EVENT_KEY_DOWN => Event{ .key_down = KeyEvent.from(sdl_event.key) },
            c.SDL_EVENT_KEY_UP => Event{ .key_up = KeyEvent.from(sdl_event.key) },
            c.SDL_EVENT_MOUSE_MOTION => Event{ .mouse_motion = MouseMotionEvent.from(sdl_event.motion) },
            c.SDL_EVENT_MOUSE_BUTTON_DOWN => Event{ .mouse_button_down = MouseButtonEvent.from(sdl_event.button) },
            c.SDL_EVENT_MOUSE_BUTTON_UP => Event{ .mouse_button_up = MouseButtonEvent.from(sdl_event.button) },
            c.SDL_EVENT_WINDOW_RESIZED => Event{ .window = WindowEvent.from(sdl_event.window) },
            c.SDL_EVENT_TEXT_INPUT => Event{ .text_input = TextInputEvent.from(sdl_event.text) },
            else => Event.unknown,
        };
    }
};

pub const KeyEvent = struct {
    scancode: Scancode,
    keycode: Keycode,
    mod: KeyMod,
    repeat: bool,

    pub fn from(key: c.SDL_KeyboardEvent) KeyEvent {
        return KeyEvent{
            .scancode = @enumFromInt(key.scancode),
            .keycode = @enumFromInt(key.key),
            .mod = KeyMod.from(key.mod),
            .repeat = key.repeat,
        };
    }
};

pub const MouseMotionEvent = struct {
    x: f32,
    y: f32,
    xrel: f32,
    yrel: f32,
    state: MouseState,

    pub fn from(motion: c.SDL_MouseMotionEvent) MouseMotionEvent {
        return MouseMotionEvent{
            .x = motion.x,
            .y = motion.y,
            .xrel = motion.xrel,
            .yrel = motion.yrel,
            .state = MouseState.from(motion.state),
        };
    }
};

pub const MouseButtonEvent = struct {
    button: MouseButton,
    x: f32,
    y: f32,
    clicks: u8,

    pub fn from(button: c.SDL_MouseButtonEvent) MouseButtonEvent {
        return MouseButtonEvent{
            .button = @enumFromInt(button.button),
            .x = button.x,
            .y = button.y,
            .clicks = button.clicks,
        };
    }
};

pub const WindowEvent = struct {
    event: WindowEventType,
    data1: i32,
    data2: i32,

    pub fn from(window: c.SDL_WindowEvent) WindowEvent {
        return WindowEvent{
            .event = @enumFromInt(window.type),
            .data1 = window.data1,
            .data2 = window.data2,
        };
    }
};

pub const TextInputEvent = struct {
    text: [32]u8,

    pub fn from(text: c.SDL_TextInputEvent) TextInputEvent {
        var result = TextInputEvent{
            .text = undefined,
        };
        var i: usize = 0;
        while (i < 32 and text.text[i] != 0) : (i += 1) {
            result.text[i] = text.text[i];
        }
        if (i < 32) {
            result.text[i] = 0;
        }
        return result;
    }
};

pub const Scancode = enum(c.SDL_Scancode) {
    unknown = c.SDL_SCANCODE_UNKNOWN,
    a = c.SDL_SCANCODE_A,
    b = c.SDL_SCANCODE_B,
    c = c.SDL_SCANCODE_C,
    // ... add more as needed
    _,
};

pub const Keycode = enum(c.SDL_Keycode) {
    unknown = c.SDLK_UNKNOWN,
    return_ = c.SDLK_RETURN,
    escape = c.SDLK_ESCAPE,
    backspace = c.SDLK_BACKSPACE,
    tab = c.SDLK_TAB,
    space = c.SDLK_SPACE,
    // ... add more as needed
    _,
};

pub const KeyMod = packed struct {
    lshift: bool = false,
    rshift: bool = false,
    lctrl: bool = false,
    rctrl: bool = false,
    lalt: bool = false,
    ralt: bool = false,
    lgui: bool = false,
    rgui: bool = false,
    num: bool = false,
    caps: bool = false,
    mode: bool = false,
    scroll: bool = false,

    pub fn from(mod: c.SDL_Keymod) KeyMod {
        return KeyMod{
            .lshift = (mod & c.SDL_KMOD_LSHIFT) != 0,
            .rshift = (mod & c.SDL_KMOD_RSHIFT) != 0,
            .lctrl = (mod & c.SDL_KMOD_LCTRL) != 0,
            .rctrl = (mod & c.SDL_KMOD_RCTRL) != 0,
            .lalt = (mod & c.SDL_KMOD_LALT) != 0,
            .ralt = (mod & c.SDL_KMOD_RALT) != 0,
            .lgui = (mod & c.SDL_KMOD_LGUI) != 0,
            .rgui = (mod & c.SDL_KMOD_RGUI) != 0,
            .num = (mod & c.SDL_KMOD_NUM) != 0,
            .caps = (mod & c.SDL_KMOD_CAPS) != 0,
            .mode = (mod & c.SDL_KMOD_MODE) != 0,
            .scroll = (mod & c.SDL_KMOD_SCROLL) != 0,
        };
    }
};

pub const MouseButton = enum(u8) {
    left = c.SDL_BUTTON_LEFT,
    middle = c.SDL_BUTTON_MIDDLE,
    right = c.SDL_BUTTON_RIGHT,
    x1 = c.SDL_BUTTON_X1,
    x2 = c.SDL_BUTTON_X2,
    _,
};

pub const MouseState = packed struct {
    left: bool = false,
    middle: bool = false,
    right: bool = false,
    x1: bool = false,
    x2: bool = false,

    pub fn from(state: u32) MouseState {
        return MouseState{
            .left = (state & c.SDL_BUTTON_LMASK) != 0,
            .middle = (state & c.SDL_BUTTON_MMASK) != 0,
            .right = (state & c.SDL_BUTTON_RMASK) != 0,
            .x1 = (state & c.SDL_BUTTON_X1MASK) != 0,
            .x2 = (state & c.SDL_BUTTON_X2MASK) != 0,
        };
    }
};

pub const WindowEventType = enum(u32) {
    shown = c.SDL_EVENT_WINDOW_SHOWN,
    hidden = c.SDL_EVENT_WINDOW_HIDDEN,
    exposed = c.SDL_EVENT_WINDOW_EXPOSED,
    moved = c.SDL_EVENT_WINDOW_MOVED,
    resized = c.SDL_EVENT_WINDOW_RESIZED,
    minimized = c.SDL_EVENT_WINDOW_MINIMIZED,
    maximized = c.SDL_EVENT_WINDOW_MAXIMIZED,
    restored = c.SDL_EVENT_WINDOW_RESTORED,
    focus_gained = c.SDL_EVENT_WINDOW_FOCUS_GAINED,
    focus_lost = c.SDL_EVENT_WINDOW_FOCUS_LOST,
    display_changed = c.SDL_EVENT_WINDOW_DISPLAY_CHANGED,
    _,
};

/// Poll for currently pending events
pub fn pollEvent() ?Event {
    var sdl_event: c.SDL_Event = undefined;
    if (c.SDL_PollEvent(&sdl_event)) {
        return Event.from(sdl_event);
    }
    return null;
}

test "event handling" {
    const sdl = @import("../core/module.zig");
    try sdl.init(.{ .video = true });
    defer sdl.quit();

    const video = @import("../video/module.zig");
    var window = try video.Window.create(
        "Test Window",
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    );
    defer window.destroy();

    // Test event polling
    while (pollEvent()) |event| {
        switch (event) {
            .quit => break,
            else => {},
        }
    }
}
