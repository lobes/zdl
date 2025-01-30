//! Semaphore synchronization primitives for SDL3.
//!
//! This module provides counting semaphores for thread synchronization:
//! - Semaphore creation with initial value
//! - Wait operations (blocking and non-blocking)
//! - Post operations for signaling
//! - Timed wait operations
//! - Resource counting and limiting
//!
//! Dependencies:
//! - Core SDL3 semaphore system
//! - Uses error.zig for error handling
//!
//! Thread safety: All semaphore operations are thread-safe. Multiple threads can
//! safely wait on and post to the same semaphore.
//!
//! Memory management: Semaphores must be explicitly destroyed when no longer needed.
//! Waiting threads are automatically released when a semaphore is destroyed.
//!
//! Example:
//! ```zig
//! // Create a semaphore with initial value 1
//! var sem = try Semaphore.create(1);
//! defer sem.destroy();
//!
//! // Wait on the semaphore
//! try sem.wait();
//!
//! // Critical section...
//!
//! // Signal the semaphore
//! sem.post();
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const core = @import("../core/module.zig");
const errors = core.errors;

/// A counting semaphore
pub const Semaphore = struct {
    handle: *c.SDL_Semaphore,

    /// Create a new semaphore with the specified initial value
    pub fn create(initial_value: u32) !Semaphore {
        const handle = c.SDL_CreateSemaphore(initial_value) orelse {
            return errors.sdlError();
        };
        return Semaphore{ .handle = handle };
    }

    /// Destroy the semaphore
    pub fn destroy(self: *Semaphore) void {
        c.SDL_DestroySemaphore(self.handle);
        self.* = undefined;
    }

    /// Wait on the semaphore (blocking)
    pub fn wait(self: Semaphore) !void {
        if (!c.SDL_SemWait(self.handle)) {
            return errors.sdlError();
        }
    }

    /// Try to wait on the semaphore (non-blocking)
    pub fn tryWait(self: Semaphore) bool {
        return c.SDL_SemTryWait(self.handle);
    }

    /// Wait on the semaphore with timeout in milliseconds
    /// Returns true if the semaphore was acquired, false if timed out
    pub fn waitTimeout(self: Semaphore, timeout_ms: u32) !bool {
        return switch (c.SDL_SemWaitTimeout(self.handle, timeout_ms)) {
            0 => true, // Got the semaphore
            c.SDL_MUTEX_TIMEDOUT => false, // Timeout
            else => errors.sdlError(),
        };
    }

    /// Signal (post to) the semaphore
    pub fn post(self: Semaphore) !void {
        if (!c.SDL_SemPost(self.handle)) {
            return errors.sdlError();
        }
    }

    /// Get the current value of the semaphore
    pub fn getValue(self: Semaphore) u32 {
        return @intCast(c.SDL_SemValue(self.handle));
    }
};

test "semaphore basic operations" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    var sem = try Semaphore.create(1);
    defer sem.destroy();

    try std.testing.expectEqual(@as(u32, 1), sem.getValue());

    try sem.wait();
    try std.testing.expectEqual(@as(u32, 0), sem.getValue());

    try sem.post();
    try std.testing.expectEqual(@as(u32, 1), sem.getValue());
}

test "semaphore try wait" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    var sem = try Semaphore.create(1);
    defer sem.destroy();

    // First try should succeed
    try std.testing.expect(sem.tryWait());
    try std.testing.expectEqual(@as(u32, 0), sem.getValue());

    // Second try should fail
    try std.testing.expect(!sem.tryWait());
    try std.testing.expectEqual(@as(u32, 0), sem.getValue());

    // Post should succeed
    try sem.post();
    try std.testing.expectEqual(@as(u32, 1), sem.getValue());
}

test "semaphore wait timeout" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    var sem = try Semaphore.create(1);
    defer sem.destroy();

    // Take the semaphore
    try sem.wait();

    // Try to wait with timeout (should fail)
    const got_sem = try sem.waitTimeout(100);
    try std.testing.expect(!got_sem);

    // Post and try again (should succeed)
    try sem.post();
    const got_sem2 = try sem.waitTimeout(100);
    try std.testing.expect(got_sem2);
}

test "semaphore multiple posts" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    var sem = try Semaphore.create(0);
    defer sem.destroy();

    // Post multiple times
    try sem.post();
    try sem.post();
    try sem.post();
    try std.testing.expectEqual(@as(u32, 3), sem.getValue());

    // Wait multiple times
    try sem.wait();
    try sem.wait();
    try sem.wait();
    try std.testing.expectEqual(@as(u32, 0), sem.getValue());
}

test "semaphore thread synchronization" {
    const init = @import("init.zig");
    try init.init(.{});
    defer init.quit();

    const thread = @import("thread.zig");

    var sem = try Semaphore.create(0);
    defer sem.destroy();

    const Context = struct {
        sem: *Semaphore,
        value: *u32,

        fn run(ctx: *@This()) void {
            // Wait for main thread to signal
            ctx.sem.wait() catch return;
            // Increment value
            ctx.value.* += 1;
            // Signal back to main thread
            ctx.sem.post() catch return;
        }
    };

    var value: u32 = 0;
    var ctx = Context{ .sem = &sem, .value = &value };

    // Create worker thread
    var worker = try thread.Thread.spawn(.{}, Context.run, .{&ctx});
    defer worker.join();

    // Signal worker to start
    try sem.post();
    // Wait for worker to complete
    try sem.wait();

    try std.testing.expectEqual(@as(u32, 1), value);
}
