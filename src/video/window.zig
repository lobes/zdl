const std = @import("std");
const zdl = @import("../../zdl.zig");
const c = zdl.c;

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
    pub fn create(title: [:0]const u8, width: u32, height: u32, flags: u32) !Window {
        const handle = c.SDL_CreateWindow(
            title.ptr,
            @intCast(width),
            @intCast(height),
            flags,
        ) orelse return error.WindowCreationFailed;
        return Window{ .handle = handle };
    }

    /// Destroy a window
    pub fn destroy(self: *Window) void {
        c.SDL_DestroyWindow(self.handle);
    }

    /// Get the window size
    pub fn getSize(self: Window) struct { width: i32, height: i32 } {
        var width: i32 = undefined;
        var height: i32 = undefined;
        c.SDL_GetWindowSize(self.handle, &width, &height);
        return .{ .width = width, .height = height };
    }

    /// Set the window's size
    pub fn setSize(self: Window, width: i32, height: i32) void {
        c.SDL_SetWindowSize(self.handle, width, height);
    }

    /// Get the window position
    pub fn getPosition(self: Window) struct { x: i32, y: i32 } {
        var x: i32 = undefined;
        var y: i32 = undefined;
        c.SDL_GetWindowPosition(self.handle, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Set the window's position
    pub fn setPosition(self: Window, x: i32, y: i32) void {
        c.SDL_SetWindowPosition(self.handle, x, y);
    }

    /// Set the window's title
    pub fn setTitle(self: Window, title: [:0]const u8) void {
        c.SDL_SetWindowTitle(self.handle, title.ptr);
    }

    pub fn show(self: *Window) void {
        c.SDL_ShowWindow(self.handle);
    }

    pub fn hide(self: *Window) void {
        c.SDL_HideWindow(self.handle);
    }
};

test "window operations" {
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    var window = try Window.create(
        "Test Window",
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    );
    defer window.destroy();

    window.setSize(1024, 768);
    window.setPosition(100, 100);
    window.setTitle("Updated Title");

    const size = window.getSize();
    try std.testing.expectEqual(@as(i32, 1024), size.width);
    try std.testing.expectEqual(@as(i32, 768), size.height);

    const pos = window.getPosition();
    try std.testing.expectEqual(@as(i32, 100), pos.x);
    try std.testing.expectEqual(@as(i32, 100), pos.y);
}
