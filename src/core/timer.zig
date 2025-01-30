//! High-resolution timing utilities for SDL3.
//!
//! This module provides timing and delay functionality:
//! - High-resolution time queries
//! - Millisecond and nanosecond precision
//! - Frame rate control
//! - Delay operations
//! - Timer pause/resume support
//!
//! Dependencies:
//! - Core SDL3 timer functionality
//! - Uses init.zig for initialization
//!
//! Thread safety: Most timer operations are thread-safe.
//! Each Timer instance should be used by a single thread,
//! but different threads can safely use different timers.
//!
//! Performance notes:
//! - getTicksNS() provides higher precision but may be slower
//! - delay() yields CPU time to other processes
//! - FrameTimer helps maintain consistent frame rates
//!
//! Example:
//! ```zig
//! // Basic delay
//! delay(16); // Wait ~16ms
//!
//! // High precision timer
//! var timer = Timer.init();
//! timer.start();
//! // Do work...
//! const elapsed = timer.getTicks();
//!
//! // Frame rate control
//! var frame_timer = FrameTimer.init(60);
//! frame_timer.start();
//! while (running) {
//!     // Render frame...
//!     frame_timer.update(); // Maintains ~60 FPS
//! }
//! ```

const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const testing = @import("std").testing;

/// Get the number of milliseconds since SDL library initialization
pub fn getTicksMS() u64 {
    return c.SDL_GetTicks();
}

/// Get the number of milliseconds since SDL library initialization with higher precision
pub fn getTicksNS() u64 {
    return c.SDL_GetTicksNS();
}

/// Wait a specified number of milliseconds
pub fn delay(ms: u32) void {
    c.SDL_Delay(ms);
}

/// A high resolution timer
pub const Timer = struct {
    start_ticks: u64 = 0,
    paused_ticks: u64 = 0,
    paused: bool = false,
    started: bool = false,

    /// Create a new timer
    pub fn init() Timer {
        return Timer{};
    }

    /// Start the timer
    pub fn start(self: *Timer) void {
        self.started = true;
        self.paused = false;
        self.start_ticks = getTicksMS();
        self.paused_ticks = 0;
    }

    /// Stop the timer
    pub fn stop(self: *Timer) void {
        self.started = false;
        self.paused = false;
        self.start_ticks = 0;
        self.paused_ticks = 0;
    }

    /// Pause the timer
    pub fn pause(self: *Timer) void {
        if (self.started and !self.paused) {
            self.paused = true;
            self.paused_ticks = getTicksMS() - self.start_ticks;
            self.start_ticks = 0;
        }
    }

    /// Unpause the timer
    pub fn unpause(self: *Timer) void {
        if (self.started and self.paused) {
            self.paused = false;
            self.start_ticks = getTicksMS() - self.paused_ticks;
            self.paused_ticks = 0;
        }
    }

    /// Get the timer's time in milliseconds
    pub fn getTicks(self: Timer) u64 {
        if (!self.started) {
            return 0;
        }

        if (self.paused) {
            return self.paused_ticks;
        }

        return getTicksMS() - self.start_ticks;
    }

    /// Check if the timer is started
    pub fn isStarted(self: Timer) bool {
        return self.started;
    }

    /// Check if the timer is paused
    pub fn isPaused(self: Timer) bool {
        return self.started and self.paused;
    }
};

/// Frame rate controller
pub const FrameTimer = struct {
    timer: Timer,
    frame_count: u32 = 0,
    fps: f32 = 0,
    target_fps: f32,
    frame_delay: u32,

    /// Create a new frame timer with a target FPS
    pub fn init(target_fps: f32) FrameTimer {
        return .{
            .timer = Timer.init(),
            .target_fps = target_fps,
            .frame_delay = @intFromFloat(1000.0 / target_fps),
        };
    }

    /// Start the frame timer
    pub fn start(self: *FrameTimer) void {
        self.timer.start();
    }

    /// Update the frame timer and delay if necessary to maintain target FPS
    pub fn update(self: *FrameTimer) void {
        self.frame_count += 1;

        const elapsed = self.timer.getTicks();
        if (elapsed >= 1000) {
            self.fps = @as(f32, @floatFromInt(self.frame_count)) * (1000.0 / @as(f32, @floatFromInt(elapsed)));
            self.frame_count = 0;
            self.timer.start();
        }

        // Delay to maintain target FPS
        const frame_time = getTicksMS() - self.timer.start_ticks;
        if (frame_time < self.frame_delay) {
            delay(self.frame_delay - @as(u32, @intCast(frame_time)));
        }
    }

    /// Get the current FPS
    pub fn getFPS(self: FrameTimer) f32 {
        return self.fps;
    }
};

test "timer operations" {
    const init = @import("init.zig");
    try init.init(.{ .video = true });
    defer init.quit();

    // Test basic timer
    var timer = Timer.init();
    timer.start();
    delay(100);
    const elapsed = timer.getTicks();
    try testing.expect(elapsed >= 100);

    // Test pause/unpause
    timer.pause();
    const paused_time = timer.getTicks();
    delay(100);
    try testing.expectEqual(paused_time, timer.getTicks());
    timer.unpause();
    delay(100);
    try testing.expect(timer.getTicks() > paused_time);

    // Test frame timer
    var frame_timer = FrameTimer.init(60);
    frame_timer.start();

    // Run for at least 1 second to get a valid FPS reading
    delay(1000);
    frame_timer.update();
    try testing.expect(frame_timer.getFPS() > 0);
}
