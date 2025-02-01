const std = @import("std");
const build_options = @import("build_options");

pub const c = @cImport({
    @cInclude("SDL3/SDL.h");
    if (build_options.enable_mixer) {
        @cInclude("SDL3_mixer/SDL_mixer.h");
    }
    if (build_options.enable_ttf) {
        @cInclude("SDL3_ttf/SDL_ttf.h");
    }
});

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

// Core module (always enabled)
pub const core = @import("core/module.zig");

// Optional modules based on build options
pub const audio = if (build_options.enable_audio) @import("audio/module.zig") else struct {};
pub const graphics = if (build_options.enable_graphics) @import("graphics/module.zig") else struct {};
pub const input = if (build_options.enable_input) @import("input/module.zig") else struct {};
pub const mixer = if (build_options.enable_mixer) @import("mixer/mixer.zig") else struct {};
pub const system = if (build_options.enable_system) @import("system/module.zig") else struct {};
pub const ttf = if (build_options.enable_ttf) @import("ttf/ttf.zig") else struct {};
pub const video = if (build_options.enable_video) @import("video/module.zig") else struct {};

// Video-related modules (depend on video being enabled)
pub const render = if (build_options.enable_video) @import("video/render.zig") else struct {};
pub const surface = if (build_options.enable_video) @import("video/surface.zig") else struct {};
pub const pixels = if (build_options.enable_video) video.pixels else struct {};
pub const rect = if (build_options.enable_video) video.rect else struct {};

// Core events and timer are always available
pub const events = core.events;
pub const timer = core.timer;

test {
    _ = @import("tests.zig");
}
