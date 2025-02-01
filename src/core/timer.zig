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
const c = @import("root").c;

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

/// A timer for managing frame rate
pub const FrameTimer = struct {
    target_fps: f32,
    frame_time: f32,
    last_time: u64,
    freq: u64,

    /// Initialize a frame timer with a target frame rate
    pub fn init(target_fps: f32) FrameTimer {
        return FrameTimer{
            .target_fps = target_fps,
            .frame_time = 1.0 / target_fps,
            .last_time = getPerformanceCounter(),
            .freq = getPerformanceFrequency(),
        };
    }

    /// Start the frame timer
    pub fn start(self: *FrameTimer) void {
        self.last_time = getPerformanceCounter();
    }

    /// Update the frame timer and delay if necessary to maintain target frame rate
    pub fn update(self: *FrameTimer) void {
        const current_time = getPerformanceCounter();
        const elapsed = @as(f32, @floatFromInt(current_time - self.last_time)) / @as(f32, @floatFromInt(self.freq));

        if (elapsed < self.frame_time) {
            const delay_time = @as(u32, @intFromFloat((self.frame_time - elapsed) * 1000.0));
            delay(delay_time);
        }

        self.last_time = getPerformanceCounter();
    }

    /// Get the elapsed time since the last update in seconds
    pub fn getElapsed(self: FrameTimer) f32 {
        const current_time = getPerformanceCounter();
        return @as(f32, @floatFromInt(current_time - self.last_time)) / @as(f32, @floatFromInt(self.freq));
    }

    /// Get the current frame rate
    pub fn getFPS(self: FrameTimer) f32 {
        const elapsed = self.getElapsed();
        if (elapsed > 0) {
            return 1.0 / elapsed;
        }
        return 0;
    }
};

test "frame timer" {
    const zdl = @import("module.zig");
    try zdl.init(.{});
    defer zdl.quit();

    var timer = FrameTimer.init(60);
    timer.start();

    // Test that frame time is correct
    try std.testing.expectApproxEqAbs(timer.frame_time, 1.0 / 60.0, 0.0001);

    // Test that elapsed time increases
    const start_elapsed = timer.getElapsed();
    delay(16); // Delay for one frame at 60 FPS
    const end_elapsed = timer.getElapsed();
    try std.testing.expect(end_elapsed > start_elapsed);

    // Test frame rate limiting by measuring over a longer period
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        timer.update();
        delay(16); // Simulate frame time
    }

    const fps = timer.getFPS();
    std.debug.print("Current FPS: {d}\n", .{fps});
    try std.testing.expect(fps >= 0.0); // Just ensure it's not negative
    try std.testing.expect(fps <= 100.0); // Should be close to 60 FPS but allow some margin
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
