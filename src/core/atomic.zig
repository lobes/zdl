//! Atomic operations for SDL3.
//!
//! IMPORTANT: If you are not an expert in concurrent lockless programming,
//! you should not be using these functions directly. Use mutexes instead.
//!
//! This module provides atomic operations that are implemented using
//! processor-specific atomic operations when possible, falling back to
//! mutex-based implementations when necessary.
//!
//! Thread safety: All operations are atomic and thread-safe.
//! Memory ordering: All operations that modify memory are full memory barriers.
//!
//! Example:
//! ```zig
//! var counter = Atomic(i32).init(0);
//! const old_value = counter.add(1);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// An atomic integer type
pub fn Atomic(comptime T: type) type {
    return struct {
        value: c.SDL_AtomicInt,

        const Self = @This();

        /// Initialize a new atomic value
        pub fn init(value: T) Self {
            return Self{ .value = @intCast(value) };
        }

        /// Get the current value
        pub fn load(self: *const Self) T {
            return @intCast(c.SDL_AtomicGet(@constCast(&self.value)));
        }

        /// Set to a new value and return the old value
        pub fn exchange(self: *Self, new_value: T) T {
            return @intCast(c.SDL_AtomicSet(&self.value, @intCast(new_value)));
        }

        /// Compare and exchange values
        pub fn compareExchange(self: *Self, expected: T, new_value: T) bool {
            var expected_value: c.SDL_AtomicInt = @intCast(expected);
            return c.SDL_AtomicCAS(&self.value, &expected_value, @intCast(new_value));
        }

        /// Add to the current value and return the old value
        pub fn add(self: *Self, value: T) T {
            return @intCast(c.SDL_AtomicAdd(&self.value, @intCast(value)));
        }
    };
}

/// Memory barrier types
pub const MemoryBarrier = enum {
    /// Full memory barrier
    full,
    /// Read memory barrier
    read,
    /// Write memory barrier
    write,
};

/// Insert a memory barrier
pub fn memoryBarrier(barrier_type: MemoryBarrier) void {
    switch (barrier_type) {
        .full => c.SDL_MemoryBarrierReleaseFunction(),
        .read => c.SDL_MemoryBarrierAcquireFunction(),
        .write => c.SDL_MemoryBarrierReleaseFunction(),
    }
}

test "atomic initialization" {
    const atomic = Atomic(i32).init(42);
    try std.testing.expectEqual(@as(i32, 42), atomic.load());
}

test "atomic exchange" {
    var atomic = Atomic(i32).init(1);
    const old_value = atomic.exchange(2);
    try std.testing.expectEqual(@as(i32, 1), old_value);
    try std.testing.expectEqual(@as(i32, 2), atomic.load());
}

test "atomic compare exchange" {
    var atomic = Atomic(i32).init(1);
    const success = atomic.compareExchange(1, 2);
    try std.testing.expect(success);
    try std.testing.expectEqual(@as(i32, 2), atomic.load());

    const fail = atomic.compareExchange(1, 3);
    try std.testing.expect(!fail);
    try std.testing.expectEqual(@as(i32, 2), atomic.load());
}

test "atomic add" {
    var atomic = Atomic(i32).init(1);
    const old_value = atomic.add(2);
    try std.testing.expectEqual(@as(i32, 1), old_value);
    try std.testing.expectEqual(@as(i32, 3), atomic.load());
}

test "memory barriers" {
    var atomic = Atomic(i32).init(0);

    memoryBarrier(.write);
    _ = atomic.exchange(1);
    memoryBarrier(.full);
    const value = atomic.load();
    memoryBarrier(.read);

    try std.testing.expectEqual(@as(i32, 1), value);
}

test "atomic operations ordering" {
    var atomic1 = Atomic(i32).init(0);
    var atomic2 = Atomic(i32).init(0);

    // Test that operations are properly ordered with memory barriers
    _ = atomic1.exchange(1);
    memoryBarrier(.full);
    _ = atomic2.exchange(1);
    memoryBarrier(.full);

    try std.testing.expectEqual(@as(i32, 1), atomic1.load());
    try std.testing.expectEqual(@as(i32, 1), atomic2.load());
}

test "concurrent atomic operations" {
    const TestContext = struct {
        counter: Atomic(i32),

        fn init() @This() {
            return .{
                .counter = Atomic(i32).init(0),
            };
        }
    };

    var context = TestContext.init();

    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            const ctx = @as(*TestContext, @ptrCast(@alignCast(data.?)));
            _ = ctx.counter.add(1);
            return 0;
        }
    }).func;

    // Create multiple threads that increment the counter
    var threads: [4]*c.SDL_Thread = undefined;
    for (&threads) |*t| {
        t.* = c.SDL_CreateThread(threadFn, "worker", &context) orelse {
            @panic("Failed to create thread");
        };
    }

    // Wait for all threads
    for (threads) |t| {
        var status: c_int = undefined;
        c.SDL_WaitThread(t, &status);
    }

    // Check final counter value
    try std.testing.expectEqual(@as(i32, 4), context.counter.load());
}
