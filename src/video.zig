const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");
const testing = std.testing;
const errors = @import("errors.zig");

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
        x: i32 = c.SDL_WINDOWPOS_UNDEFINED,
        y: i32 = c.SDL_WINDOWPOS_UNDEFINED,
        display_id: u32 = 0,

        pub fn toSDLFlags(self: CreateFlags) c.SDL_WindowFlags {
            var flags: c.SDL_WindowFlags = 0;
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
    pub fn create(
        title: [:0]const u8,
        width: i32,
        height: i32,
        flags: CreateFlags,
    ) !Window {
        const handle = c.SDL_CreateWindow(
            title,
            width,
            height,
            flags.toSDLFlags(),
        ) orelse return errors.SDLError.WindowCreationFailed;

        // Set position after creation
        if (flags.x != c.SDL_WINDOWPOS_UNDEFINED or flags.y != c.SDL_WINDOWPOS_UNDEFINED) {
            _ = c.SDL_SetWindowPosition(@ptrCast(handle), flags.x, flags.y);
        }

        // Set fullscreen display mode if needed
        if (flags.fullscreen) {
            // Get the display the window is on
            const display_id = c.SDL_GetDisplayForWindow(@ptrCast(handle));
            std.debug.print("Window is on display {d}\n", .{display_id});

            const mode = c.SDL_GetCurrentDisplayMode(display_id) orelse {
                std.debug.print("Failed to get display mode: {s}\n", .{c.SDL_GetError()});
                return errors.SDLError.WindowCreationFailed;
            };
            std.debug.print("Setting fullscreen mode: {}x{} @ {}Hz\n", .{ mode.*.w, mode.*.h, mode.*.refresh_rate });
            if (!c.SDL_SetWindowFullscreenMode(@ptrCast(handle), mode)) {
                std.debug.print("Failed to set fullscreen mode: {s}\n", .{c.SDL_GetError()});
                return errors.SDLError.WindowCreationFailed;
            }
        }

        return Window{ .handle = handle };
    }

    /// Destroy the window
    pub fn destroy(self: *Window) void {
        c.SDL_DestroyWindow(self.handle);
    }

    /// Get the window size
    pub fn getSize(self: Window) struct { width: i32, height: i32 } {
        var width: i32 = undefined;
        var height: i32 = undefined;
        _ = c.SDL_GetWindowSize(self.handle, &width, &height);
        return .{ .width = width, .height = height };
    }

    /// Set the window size
    pub fn setSize(self: Window, width: i32, height: i32) void {
        _ = c.SDL_SetWindowSize(self.handle, width, height);
    }

    /// Get the window position
    pub fn getPosition(self: Window) struct { x: i32, y: i32 } {
        var x: i32 = undefined;
        var y: i32 = undefined;
        _ = c.SDL_GetWindowPosition(self.handle, &x, &y);
        return .{ .x = x, .y = y };
    }

    /// Set the window position
    pub fn setPosition(self: Window, x: i32, y: i32) void {
        _ = c.SDL_SetWindowPosition(self.handle, x, y);
    }

    /// Set the window title
    pub fn setTitle(self: Window, title: [:0]const u8) void {
        _ = c.SDL_SetWindowTitle(self.handle, title);
    }
};

test "window creation" {
    const init = @import("init.zig");
    try init.init(.{ .video = true });
    defer init.quit();

    var window = try Window.create(
        "Test Window",
        800,
        600,
        .{ .resizable = true },
    );
    defer window.destroy();

    const size = window.getSize();
    try testing.expectEqual(@as(i32, 800), size.width);
    try testing.expectEqual(@as(i32, 600), size.height);

    window.setSize(1024, 768);
    const new_size = window.getSize();
    try testing.expectEqual(@as(i32, 1024), new_size.width);
    try testing.expectEqual(@as(i32, 768), new_size.height);
}
