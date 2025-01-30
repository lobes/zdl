//! Audio mixing and music functionality for SDL3.
//!
//! This module provides advanced audio features:
//! - Sound effect mixing and playback
//! - Music file loading and streaming
//! - Channel management and grouping
//! - Volume and panning control
//! - Effect processing (distance, position, etc.)
//! - Support for multiple audio formats:
//!   - WAV (built-in)
//!   - FLAC
//!   - MP3
//!   - OGG
//!   - MOD/XM/IT/S3M
//!   - MIDI
//!
//! Example:
//! ```zig
//! // Initialize mixer
//! try mixer.init(.{
//!     .frequency = 44100,
//!     .format = .s16_sys,
//!     .channels = 2,
//!     .chunk_size = 2048,
//! });
//! defer mixer.quit();
//!
//! // Load and play sound
//! const sound = try mixer.Chunk.load("sound.wav");
//! defer sound.free();
//! const channel = try mixer.playChannel(-1, sound, 0);
//! ```

const std = @import("std");
const core = @import("../core/module.zig");

const c = @cImport({
    @cInclude("/Users/lobes/things/SDL_mixer/include/SDL3_mixer/SDL_mixer.h");
});

pub const InitFlags = packed struct {
    flac: bool = false,
    mod: bool = false,
    mp3: bool = false,
    ogg: bool = false,
    mid: bool = false,
    opus: bool = false,
    _padding: u26 = 0,

    fn toSDL(self: InitFlags) c_int {
        var flags: c_int = 0;
        if (self.flac) flags |= c.MIX_INIT_FLAC;
        if (self.mod) flags |= c.MIX_INIT_MOD;
        if (self.mp3) flags |= c.MIX_INIT_MP3;
        if (self.ogg) flags |= c.MIX_INIT_OGG;
        if (self.mid) flags |= c.MIX_INIT_MID;
        if (self.opus) flags |= c.MIX_INIT_OPUS;
        return flags;
    }
};

pub const OpenFlags = packed struct {
    flac: bool = false,
    mod: bool = false,
    mp3: bool = false,
    ogg: bool = false,
    mid: bool = false,
    opus: bool = false,
    _padding: u26 = 0,

    fn toSDL(self: OpenFlags) c_int {
        var flags: c_int = 0;
        if (self.flac) flags |= c.MIX_INIT_FLAC;
        if (self.mod) flags |= c.MIX_INIT_MOD;
        if (self.mp3) flags |= c.MIX_INIT_MP3;
        if (self.ogg) flags |= c.MIX_INIT_OGG;
        if (self.mid) flags |= c.MIX_INIT_MID;
        if (self.opus) flags |= c.MIX_INIT_OPUS;
        return flags;
    }
};

pub const InitConfig = struct {
    frequency: i32 = 44100,
    format: core.audio.AudioFormat = .s16_sys,
    channels: i32 = 2,
    chunk_size: i32 = 2048,
    flags: InitFlags = .{},
};

/// Initialize SDL_mixer with the given configuration
pub fn init(config: InitConfig) !void {
    // Initialize requested formats
    const init_flags = config.flags.toSDL();
    if (init_flags != 0) {
        const loaded = c.Mix_Init(init_flags);
        if ((loaded & init_flags) != init_flags) {
            return error.MixerInitFailed;
        }
    }

    // Open audio device
    if (c.Mix_OpenAudio(
        config.frequency,
        @intFromEnum(config.format),
        config.channels,
        config.chunk_size,
    ) < 0) {
        return error.OpenAudioFailed;
    }
}

/// Clean up all SDL_mixer state
pub fn quit() void {
    c.Mix_CloseAudio();
    c.Mix_Quit();
}

/// A chunk of audio data
pub const Chunk = struct {
    handle: *c.Mix_Chunk,

    /// Load WAV, AIFF, RIFF, OGG, or VOC audio from a file
    pub fn load(file: [:0]const u8) !Chunk {
        const handle = c.Mix_LoadWAV(file.ptr) orelse {
            return error.LoadChunkFailed;
        };
        return Chunk{ .handle = handle };
    }

    /// Free the chunk
    pub fn free(self: Chunk) void {
        c.Mix_FreeChunk(self.handle);
    }

    /// Set chunk volume (0-128)
    pub fn setVolume(self: Chunk, volume: i32) i32 {
        return c.Mix_VolumeChunk(self.handle, volume);
    }
};

/// A music stream
pub const Music = struct {
    handle: *c.Mix_Music,

    /// Load music from a file
    pub fn load(file: [:0]const u8) !Music {
        const handle = c.Mix_LoadMUS(file.ptr) orelse {
            return error.LoadMusicFailed;
        };
        return Music{ .handle = handle };
    }

    /// Free the music stream
    pub fn free(self: Music) void {
        c.Mix_FreeMusic(self.handle);
    }
};

/// Play a chunk on a channel (-1 for first free)
pub fn playChannel(channel: i32, chunk: Chunk, loops: i32) !i32 {
    const result = c.Mix_PlayChannel(channel, chunk.handle, loops);
    if (result < 0) return error.PlayChannelFailed;
    return result;
}

/// Play music
pub fn playMusic(music: Music, loops: i32) !void {
    if (c.Mix_PlayMusic(music.handle, loops) < 0) {
        return error.PlayMusicFailed;
    }
}

/// Set channel volume (0-128)
pub fn setVolume(channel: i32, volume: i32) i32 {
    return c.Mix_Volume(channel, volume);
}

/// Set music volume (0-128)
pub fn setMusicVolume(volume: i32) i32 {
    return c.Mix_VolumeMusic(volume);
}

/// Halt playback on a channel (-1 for all channels)
pub fn haltChannel(channel: i32) void {
    _ = c.Mix_HaltChannel(channel);
}

/// Halt music playback
pub fn haltMusic() void {
    _ = c.Mix_HaltMusic();
}

/// Fade out a channel over ms milliseconds (-1 for all channels)
pub fn fadeOutChannel(channel: i32, ms: i32) !void {
    if (c.Mix_FadeOutChannel(channel, ms) == 0) {
        return error.FadeOutChannelFailed;
    }
}

/// Fade out music over ms milliseconds
pub fn fadeOutMusic(ms: i32) !void {
    if (c.Mix_FadeOutMusic(ms) == 0) {
        return error.FadeOutMusicFailed;
    }
}

test "mixer init/quit" {
    // Initialize with defaults
    try init(.{});
    defer quit();

    // Initialize with all formats
    try init(.{
        .frequency = 48000,
        .format = .f32_sys,
        .channels = 2,
        .chunk_size = 4096,
        .flags = .{
            .flac = true,
            .mod = true,
            .mp3 = true,
            .ogg = true,
            .mid = true,
            .opus = true,
        },
    });
}

test "mixer volume" {
    try init(.{});
    defer quit();

    // Test channel volume
    const old_vol = setVolume(-1, 64);
    _ = setVolume(-1, old_vol);

    // Test music volume
    const old_music_vol = setMusicVolume(64);
    _ = setMusicVolume(old_music_vol);
}
