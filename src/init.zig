const c = @cImport({
    @cInclude("SDL.h");
});

const std = @import("std");
const errors = @import("errors.zig");

pub const InitFlags = struct {
    video: bool = false,
    audio: bool = false,
    events: bool = true,
    gamepad: bool = false,

    pub fn toSDLFlags(self: InitFlags) c.SDL_InitFlags {
        var flags: c.SDL_InitFlags = 0;
        if (self.video) flags |= c.SDL_INIT_VIDEO;
        if (self.audio) flags |= c.SDL_INIT_AUDIO;
        if (self.events) flags |= c.SDL_INIT_EVENTS;
        if (self.gamepad) flags |= c.SDL_INIT_GAMEPAD;
        return flags;
    }
};

/// Initialize SDL with the specified subsystems
pub fn init(flags: InitFlags) !void {
    if (!c.SDL_Init(flags.toSDLFlags())) {
        return errors.SDLError.InitializationFailed;
    }
}

/// Shut down SDL and all initialized subsystems
pub fn quit() void {
    c.SDL_Quit();
}

test "initialization" {
    try init(.{ .video = true });
    defer quit();

    // Test that SDL is properly initialized
    try std.testing.expect(c.SDL_WasInit(c.SDL_INIT_VIDEO) != 0);
}
