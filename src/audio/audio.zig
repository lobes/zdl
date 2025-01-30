//! Audio functionality for SDL3.
//!
//! This module provides audio playback and capture:
//! - Device management
//! - Audio callbacks
//! - Format conversion
//! - Stream handling
//!
//! Dependencies:
//! - Core SDL3 audio functionality
//!
//! Thread safety: Audio callbacks can be called from any thread.
//! Device management should be done from the main thread.
//!
//! Example:
//! ```zig
//! // Open audio device
//! var spec = AudioSpec{
//!     .freq = 44100,
//!     .format = .f32_sys,
//!     .channels = 2,
//!     .samples = 4096,
//! };
//! const device = try audio.openDevice(null, false, &spec, null);
//! defer device.close();
//!
//! // Start playing
//! device.pause(false);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Audio format
pub const AudioFormat = enum(u16) {
    u8 = c.SDL_AUDIO_U8,
    s8 = c.SDL_AUDIO_S8,
    u16_lsb = c.SDL_AUDIO_U16LSB,
    s16_lsb = c.SDL_AUDIO_S16LSB,
    u16_msb = c.SDL_AUDIO_U16MSB,
    s16_msb = c.SDL_AUDIO_S16MSB,
    u16_sys = c.SDL_AUDIO_U16SYS,
    s16_sys = c.SDL_AUDIO_S16SYS,
    s32_lsb = c.SDL_AUDIO_S32LSB,
    s32_msb = c.SDL_AUDIO_S32MSB,
    s32_sys = c.SDL_AUDIO_S32SYS,
    f32_lsb = c.SDL_AUDIO_F32LSB,
    f32_msb = c.SDL_AUDIO_F32MSB,
    f32_sys = c.SDL_AUDIO_F32SYS,
};

/// Audio device specification
pub const AudioSpec = extern struct {
    freq: i32,
    format: AudioFormat,
    channels: u8,
    silence: u8 = 0,
    samples: u16,
    padding: u16 = 0,
    size: u32 = 0,
    callback: ?AudioCallback = null,
    userdata: ?*anyopaque = null,
};

/// Audio device handle
pub const AudioDevice = struct {
    id: c.SDL_AudioDeviceID,
    is_capture: bool,

    /// Close an audio device
    pub fn close(self: AudioDevice) void {
        c.SDL_CloseAudioDevice(self.id);
    }

    /// Pause/unpause an audio device
    pub fn pause(self: AudioDevice, pause_on: bool) void {
        c.SDL_PauseAudioDevice(self.id, if (pause_on) 1 else 0);
    }

    /// Get the current audio status
    pub fn getStatus(self: AudioDevice) bool {
        return c.SDL_GetAudioDeviceStatus(self.id) == c.SDL_AUDIO_PLAYING;
    }

    /// Queue more audio on non-callback devices
    pub fn queueAudio(self: AudioDevice, data: []const u8) !void {
        if (c.SDL_QueueAudio(self.id, data.ptr, data.len) < 0) {
            return error.QueueAudioFailed;
        }
    }

    /// Get the number of bytes of still-queued audio
    pub fn getQueuedAudioSize(self: AudioDevice) u32 {
        return c.SDL_GetQueuedAudioSize(self.id);
    }

    /// Drop any queued audio data
    pub fn clearQueuedAudio(self: AudioDevice) void {
        c.SDL_ClearQueuedAudio(self.id);
    }

    /// Lock the audio device
    pub fn lock(self: AudioDevice) void {
        c.SDL_LockAudioDevice(self.id);
    }

    /// Unlock the audio device
    pub fn unlock(self: AudioDevice) void {
        c.SDL_UnlockAudioDevice(self.id);
    }
};

/// Audio callback function
pub const AudioCallback = *const fn (userdata: ?*anyopaque, stream: [*]u8, len: i32) void;

/// Get the number of built-in audio drivers
pub fn getNumDrivers() i32 {
    return c.SDL_GetNumAudioDrivers();
}

/// Get the name of a built in audio driver
pub fn getDriver(index: i32) ?[:0]const u8 {
    const name = c.SDL_GetAudioDriver(index) orelse return null;
    return std.mem.span(name);
}

/// Get the name of the current audio driver
pub fn getCurrentDriver() ?[:0]const u8 {
    const name = c.SDL_GetCurrentAudioDriver() orelse return null;
    return std.mem.span(name);
}

/// Get the number of audio devices
pub fn getNumDevices(is_capture: bool) i32 {
    return c.SDL_GetNumAudioDevices(if (is_capture) 1 else 0);
}

/// Get the name of a specific audio device
pub fn getDeviceName(index: i32, is_capture: bool) ?[:0]const u8 {
    const name = c.SDL_GetAudioDeviceName(index, if (is_capture) 1 else 0) orelse return null;
    return std.mem.span(name);
}

/// Open an audio device
pub fn openDevice(device: ?[:0]const u8, is_capture: bool, desired: *AudioSpec, obtained: ?*AudioSpec) !AudioDevice {
    const device_id = c.SDL_OpenAudioDevice(
        if (device) |d| d.ptr else null,
        if (is_capture) 1 else 0,
        desired,
        obtained,
        0,
    );
    if (device_id == 0) return error.OpenAudioDeviceFailed;
    return AudioDevice{ .id = device_id, .is_capture = is_capture };
}

/// Convert audio data between different formats
pub fn convert(dst_format: AudioFormat, src_format: AudioFormat, data: []const u8) ![]u8 {
    const src_size = data.len;
    const dst_size = src_size * @sizeOf(dst_format) / @sizeOf(src_format);
    const dst = try std.heap.c_allocator.alloc(u8, dst_size);
    errdefer std.heap.c_allocator.free(dst);

    if (!c.SDL_ConvertAudioSamples(
        @intFromEnum(src_format),
        1,
        src_size,
        data.ptr,
        @intFromEnum(dst_format),
        1,
        dst_size,
        dst.ptr,
    )) {
        return error.ConvertAudioFailed;
    }

    return dst;
}

test "audio basics" {
    try core.init.init(.{ .audio = true });
    defer core.init.quit();

    // Get driver info
    const num_drivers = getNumDrivers();
    try std.testing.expect(num_drivers > 0);

    const driver = getDriver(0);
    if (driver) |d| try std.testing.expect(d.len > 0);

    const current_driver = getCurrentDriver();
    if (current_driver) |driver_name| try std.testing.expect(driver_name.len > 0);

    // Get device info
    const num_output = getNumDevices(false);
    try std.testing.expect(num_output >= 0);

    const num_input = getNumDevices(true);
    try std.testing.expect(num_input >= 0);

    if (num_output > 0) {
        const name = getDeviceName(0, false);
        if (name) |n| try std.testing.expect(n.len > 0);
    }

    // Try to open default output device
    var spec = AudioSpec{
        .freq = 44100,
        .format = .f32_sys,
        .channels = 2,
        .samples = 4096,
    };

    const device = openDevice(null, false, &spec, null) catch |err| switch (err) {
        error.OpenAudioDeviceFailed => return, // Skip if no audio device
        else => return err,
    };
    defer device.close();

    // Test device operations
    device.pause(true);
    try std.testing.expect(!device.getStatus());

    device.pause(false);
    try std.testing.expect(device.getStatus());

    // Test audio conversion
    const src = [_]u8{ 0, 1, 2, 3 };
    const dst = try convert(.u16_sys, .u8, &src);
    defer std.heap.c_allocator.free(dst);
    try std.testing.expect(dst.len == src.len * 2);
}
