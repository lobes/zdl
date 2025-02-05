//! Timer and frame rate management utilities.
//!
//! This module provides utilities for:
//! - Frame rate control
//! - High resolution timing
//! - Frame time measurement
//! - Frame rate limiting
//!
//! Dependencies:
//! - Core SDL3 timer functions
//!
//! Thread safety: SDL's timer functions are thread-safe.
//!
//! Example:
//! ```zig
//! // Create a frame timer for 60 FPS
//! var frame_timer = FrameTimer.init(60);
//! frame_timer.start();
//!
//! // Game loop
//! while (running) {
//!     // Update game state
//!     update();
//!     // Render frame
//!     render();
//!     // Maintain target frame rate
//!     frame_timer.update();
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// Get the number of milliseconds since SDL library initialization
pub fn getTicks() u64 {
    return c.SDL_GetTicks();
}

/// Get the number of microseconds since SDL library initialization
pub fn getTicksNS() u64 {
    return c.SDL_GetTicksNS();
}

/// Wait a specified number of milliseconds
pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}

/// Wait a specified number of microseconds
pub fn delayNS(ns: u64) void {
    c.SDL_DelayNS(ns);
}

/// Get the current value of the high resolution counter
pub fn getPerformanceCounter() u64 {
    return c.SDL_GetPerformanceCounter();
}

/// Get the count per second of the high resolution counter
pub fn getPerformanceFrequency() u64 {
    return c.SDL_GetPerformanceFrequency();
}

/// A high-resolution timer for frame rate control
pub const FrameTimer = struct {
    target_fps: f64,
    frame_delay: f64,
    last_time: u64,
    delta_time: f64,

    /// Initialize a frame timer with target FPS
    pub fn init(target_fps: f64) FrameTimer {
        return .{
            .target_fps = target_fps,
            .frame_delay = 1000.0 / target_fps,
            .last_time = getTicks(),
            .delta_time = 0,
        };
    }

    /// Update the timer and delay if necessary to maintain target FPS
    pub fn update(self: *FrameTimer) void {
        const current_time = getTicks();
        const frame_time = @as(f64, @floatFromInt(current_time - self.last_time));

        if (frame_time < self.frame_delay) {
            const delay_time = @as(u32, @intFromFloat(self.frame_delay - frame_time));
            delay(delay_time);
        }

        self.last_time = getTicks();
        self.delta_time = frame_time / 1000.0;
    }

    /// Get the time elapsed since the last frame in seconds
    pub fn getDeltaTime(self: FrameTimer) f64 {
        return self.delta_time;
    }

    /// Get the current FPS
    pub fn getFPS(self: FrameTimer) f64 {
        return if (self.delta_time > 0) 1.0 / self.delta_time else 0;
    }
};

test "timer basics" {
    const testing = std.testing;

    // Test basic timer functions
    const start_ticks = getTicks();
    delay(10);
    const end_ticks = getTicks();
    try testing.expect(end_ticks >= start_ticks + 10);

    // Test frame timer
    var frame_timer = FrameTimer.init(60);
    try testing.expect(frame_timer.target_fps == 60);
    try testing.expect(frame_timer.frame_delay == 1000.0 / 60.0);

    // Test frame timer update
    frame_timer.update();
    try testing.expect(frame_timer.getDeltaTime() >= 0);
    try testing.expect(frame_timer.getFPS() >= 0);
}

test "timer operations" {
    const zdl = @import("module.zig");
    try zdl.init(.{});
    defer zdl.quit();

    // Test basic timing functions
    const start = getTicks();
    delay(10);
    const end = getTicks();
    try std.testing.expect(end >= start + 10);

    // Test nanosecond precision
    const start_ns = getTicksNS();
    delayNS(1000000); // 1ms in ns
    const end_ns = getTicksNS();
    try std.testing.expect(end_ns >= start_ns + 1000000);
}
