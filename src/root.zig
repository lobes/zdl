pub const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_mixer/SDL_mixer.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
});

const std = @import("std");
pub const errors = @import("core/error.zig");

/// SDL initialization flags
pub const InitFlags = struct {
    audio: bool = false,
    video: bool = false,
    joystick: bool = false,
    haptic: bool = false,
    gamepad: bool = false,
    events: bool = true,
    sensor: bool = false,
    camera: bool = false,

    pub fn toSDLFlags(self: InitFlags) u32 {
        var flags: u32 = 0;
        if (self.audio) flags |= c.SDL_INIT_AUDIO;
        if (self.video) flags |= c.SDL_INIT_VIDEO;
        if (self.joystick) flags |= c.SDL_INIT_JOYSTICK;
        if (self.haptic) flags |= c.SDL_INIT_HAPTIC;
        if (self.gamepad) flags |= c.SDL_INIT_GAMEPAD;
        if (self.events) flags |= c.SDL_INIT_EVENTS;
        if (self.sensor) flags |= c.SDL_INIT_SENSOR;
        if (self.camera) flags |= c.SDL_INIT_CAMERA;
        return flags;
    }
};

/// Initialize SDL with the specified subsystems
pub fn init(flags: InitFlags) !void {
    if (!c.SDL_Init(flags.toSDLFlags())) {
        return errors.SDLError.InitializationFailed;
    }
}

/// Quit SDL and all initialized subsystems
pub fn quit() void {
    c.SDL_Quit();
}

// Module exports
pub const video = @import("video/module.zig");
pub const render = @import("video/render.zig");
pub const events = @import("core/events.zig");
pub const rect = @import("video/rect.zig");
pub const pixels = @import("video/pixels.zig");
pub const surface = @import("video/surface.zig");
pub const timer = @import("core/timer.zig");
pub const ttf = @import("ttf/ttf.zig");

test {
    @import("tests.zig");
}
