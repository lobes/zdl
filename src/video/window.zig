const c = @import("root").c;

const std = @import("std");
const testing = std.testing;
const root = @import("../root.zig");

/// A handle to a window
pub const Window = struct {
    handle: *c.SDL_Window,

    pub const CreateFlags = struct {
        fullscreen: bool = false,
        shown: bool = true,
        hidden: bool = false,
        borderless: bool = false,
        resizable: bool = false,
        minimized: bool = false,
        maximized: bool = false,
        x: c_int = c.SDL_WINDOWPOS_UNDEFINED,
        y: c_int = c.SDL_WINDOWPOS_UNDEFINED,
        display_id: c_uint = 0,

        pub fn toSDLFlags(self: CreateFlags) c_uint {
            var flags: c_uint = 0;
            if (self.fullscreen) flags |= c.SDL_WINDOW_FULLSCREEN;
            if (self.hidden) flags |= c.SDL_WINDOW_HIDDEN;
            if (self.borderless) flags |= c.SDL_WINDOW_BORDERLESS;
            if (self.resizable) flags |= c.SDL_WINDOW_RESIZABLE;
            if (self.minimized) flags |= c.SDL_WINDOW_MINIMIZED;
            if (self.maximized) flags |= c.SDL_WINDOW_MAXIMIZED;
            return flags;
        }
    };

    /// Create a new window
    pub fn create(title: [:0]const u8, width: i32, height: i32, flags: u32) !Window {
        const window = c.SDL_CreateWindow(title.ptr, width, height, flags) orelse {
            return error.SDLWindowCreationFailed;
        };
        return Window{ .handle = window };
    }

    /// Destroy a window
    pub fn destroy(self: *Window) void {
        c.SDL_DestroyWindow(self.handle);
    }

    /// Get the window size
    pub fn getSize(self: Window) struct { width: c_int, height: c_int } {
        var width: c_int = undefined;
        var height: c_int = undefined;
        if (!c.SDL_GetWindowSize(self.handle, &width, &height)) {
            return .{ .width = 0, .height = 0 };
        }
        return .{ .width = width, .height = height };
    }

    /// Set the window's size
    pub fn setSize(self: Window, width: c_int, height: c_int) !void {
        if (!c.SDL_SetWindowSize(self.handle, width, height)) {
            return error.SDLError;
        }
    }

    /// Get the window position
    pub fn getPosition(self: Window) struct { x: c_int, y: c_int } {
        var x: c_int = undefined;
        var y: c_int = undefined;
        if (!c.SDL_GetWindowPosition(self.handle, &x, &y)) {
            return .{ .x = 0, .y = 0 };
        }
        return .{ .x = x, .y = y };
    }

    /// Set the window's position
    pub fn setPosition(self: Window, x: c_int, y: c_int) !void {
        if (!c.SDL_SetWindowPosition(self.handle, x, y)) {
            return error.SDLError;
        }
    }

    /// Set the window's title
    pub fn setTitle(self: Window, title: [:0]const u8) !void {
        if (!c.SDL_SetWindowTitle(self.handle, title.ptr)) {
            return error.SDLError;
        }
    }

    pub fn show(self: *Window) void {
        c.SDL_ShowWindow(self.handle);
    }

    pub fn hide(self: *Window) void {
        c.SDL_HideWindow(self.handle);
    }
};

test "window operations" {
    const sdl = @import("../core/module.zig");
    try sdl.init(.{ .video = true });
    defer sdl.quit();

    var window = try Window.create(
        "Test Window",
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    );
    defer window.destroy();

    try window.setSize(1024, 768);
    try window.setPosition(100, 100);
    try window.setTitle("Updated Title");
}
