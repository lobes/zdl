pub const c = @cImport({
    @cInclude("SDL3/SDL.h");
    if (@hasDecl(@This(), "enable_mixer")) {
        @cInclude("SDL3_mixer/SDL_mixer.h");
    }
    if (@hasDecl(@This(), "enable_ttf")) {
        @cInclude("SDL3_ttf/SDL_ttf.h");
    }
});

const std = @import("std");

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
        return error.SDLError;
    }
}

/// Quit SDL and all initialized subsystems
pub fn quit() void {
    c.SDL_Quit();
}

// Module exports
pub const core = @import("core/module.zig");
pub const audio = @import("audio/module.zig");
pub const graphics = @import("graphics/module.zig");
pub const input = @import("input/module.zig");
pub const mixer = @import("mixer/mixer.zig");
pub const system = @import("system/module.zig");
pub const ttf = @import("ttf/ttf.zig");
pub const video = @import("video/module.zig");
pub const render = @import("video/render.zig");
pub const surface = @import("video/surface.zig");
pub const events = @import("core/events.zig");
pub const timer = @import("core/timer.zig");
pub const pixels = video.pixels;
pub const rect = video.rect;

test {
    _ = @import("tests.zig");
}
