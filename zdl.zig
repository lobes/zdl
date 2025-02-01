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

/// ZDL instance that manages initialization and cleanup
pub const ZDL = struct {
    flags: InitFlags,

    /// Initialize SDL with the specified subsystems
    pub fn init(flags: InitFlags) !ZDL {
        if (!c.SDL_Init(flags.toSDLFlags())) {
            return error.SDLInitFailed;
        }
        return ZDL{ .flags = flags };
    }

    /// Clean up SDL and all initialized subsystems
    pub fn deinit(self: *ZDL) void {
        _ = self;
        c.SDL_Quit();
    }
};

// Core functionality
pub const core = struct {
    // Import core modules directly
    pub usingnamespace @import("src/core/module.zig");
    pub const event = @import("src/core/event.zig");
    pub const timer = @import("src/core/timer.zig");
    pub const version = @import("src/core/version.zig");
    pub const hint = @import("src/core/hint.zig");
    pub const log = @import("src/core/log.zig");
    pub const props = @import("src/core/props.zig");
};

// Video functionality
pub const video = if (build_options.enable_video) struct {
    pub usingnamespace @import("src/video/module.zig");
    pub const render = @import("src/video/render.zig");
    pub const surface = @import("src/video/surface.zig");
    pub const window = @import("src/video/window.zig");
    pub const pixels = @import("src/video/pixels.zig");
    pub const rect = @import("src/video/rect.zig");
} else struct {};

// Direct video module exports (depend on video being enabled)
pub const render = if (build_options.enable_video) video.render else struct {};
pub const surface = if (build_options.enable_video) video.surface else struct {};
pub const pixels = if (build_options.enable_video) video.pixels else struct {};
pub const rect = if (build_options.enable_video) video.rect else struct {};

// Optional modules
pub const audio = if (build_options.enable_audio) @import("src/audio/module.zig") else struct {};
pub const graphics = if (build_options.enable_graphics) @import("src/graphics/module.zig") else struct {};
pub const input = if (build_options.enable_input) @import("src/input/module.zig") else struct {};
pub const mixer = if (build_options.enable_mixer) @import("src/mixer/module.zig") else struct {};
pub const system = if (build_options.enable_system) @import("src/system/module.zig") else struct {};
pub const ttf = if (build_options.enable_ttf) @import("src/ttf/ttf.zig") else struct {};

// Direct core exports that are always available
pub const event = core.event;
pub const timer = core.timer;

test {
    _ = @import("src/tests.zig");
}
