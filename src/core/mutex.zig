//! Mutex synchronization primitives for SDL3.
//!
//! This module provides mutual exclusion (mutex) primitives for thread synchronization:
//! - Basic mutex operations (lock/unlock)
//! - Recursive mutex support
//! - Read/write locks for shared resources
//! - Condition variables for thread signaling
//!
//! Thread safety: All operations are thread-safe by design.
//! Memory management: Resources must be explicitly destroyed when no longer needed.
//!
//! Example:
//! ```zig
//! const mutex = try Mutex.create();
//! defer mutex.destroy();
//!
//! mutex.lock();
//! defer mutex.unlock();
//! // Critical section here
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const errors = @import("error.zig");

/// A mutex for mutual exclusion between threads
pub const Mutex = struct {
    handle: *c.SDL_Mutex,

    /// Create a new mutex
    pub fn create() !Mutex {
        const handle = c.SDL_CreateMutex() orelse {
            return errors.sdlError();
        };
        return Mutex{ .handle = handle };
    }

    /// Lock the mutex
    pub fn lock(self: *Mutex) void {
        c.SDL_LockMutex(self.handle);
    }

    /// Try to lock the mutex without blocking
    pub fn tryLock(self: *Mutex) bool {
        return c.SDL_TryLockMutex(self.handle);
    }

    /// Unlock the mutex
    pub fn unlock(self: *Mutex) void {
        c.SDL_UnlockMutex(self.handle);
    }

    /// Destroy the mutex
    pub fn destroy(self: *Mutex) void {
        c.SDL_DestroyMutex(self.handle);
        self.* = undefined;
    }
};

/// A read/write lock allowing multiple readers or a single writer
pub const RWLock = struct {
    handle: *c.SDL_RWLock,

    /// Create a new read/write lock
    pub fn create() !RWLock {
        const handle = c.SDL_CreateRWLock() orelse {
            return errors.sdlError();
        };
        return RWLock{ .handle = handle };
    }

    /// Lock for reading (shared access)
    pub fn lockRead(self: *RWLock) void {
        c.SDL_LockRWLockForReading(self.handle);
    }

    /// Try to lock for reading without blocking
    pub fn tryLockRead(self: *RWLock) bool {
        return c.SDL_TryLockRWLockForReading(self.handle);
    }

    /// Lock for writing (exclusive access)
    pub fn lockWrite(self: *RWLock) void {
        c.SDL_LockRWLockForWriting(self.handle);
    }

    /// Try to lock for writing without blocking
    pub fn tryLockWrite(self: *RWLock) bool {
        return c.SDL_TryLockRWLockForWriting(self.handle);
    }

    /// Unlock the read/write lock
    pub fn unlock(self: *RWLock) void {
        c.SDL_UnlockRWLock(self.handle);
    }

    /// Destroy the read/write lock
    pub fn destroy(self: *RWLock) void {
        c.SDL_DestroyRWLock(self.handle);
        self.* = undefined;
    }
};

/// A condition variable for thread signaling
pub const Condition = struct {
    handle: *c.SDL_Condition,

    /// Create a new condition variable
    pub fn create() !Condition {
        const handle = c.SDL_CreateCondition() orelse {
            return errors.sdlError();
        };
        return Condition{ .handle = handle };
    }

    /// Signal one waiting thread
    pub fn signal(self: *Condition) void {
        c.SDL_SignalCondition(self.handle);
    }

    /// Signal all waiting threads
    pub fn broadcast(self: *Condition) void {
        c.SDL_BroadcastCondition(self.handle);
    }

    /// Wait on the condition variable
    pub fn wait(self: *Condition, mutex: *Mutex) void {
        c.SDL_WaitCondition(self.handle, mutex.handle);
    }

    /// Wait on the condition variable with timeout
    pub fn waitTimeout(self: *Condition, mutex: *Mutex, timeout_ms: i32) bool {
        return c.SDL_WaitConditionTimeout(self.handle, mutex.handle, timeout_ms);
    }

    /// Destroy the condition variable
    pub fn destroy(self: *Condition) void {
        c.SDL_DestroyCondition(self.handle);
        self.* = undefined;
    }
};

test "mutex basic operations" {
    const mutex = try Mutex.create();
    defer mutex.destroy();

    mutex.lock();
    const locked = mutex.tryLock();
    try std.testing.expect(!locked); // Already locked
    mutex.unlock();

    const success = mutex.tryLock();
    try std.testing.expect(success); // Should succeed now
    mutex.unlock();
}

test "mutex recursive locking" {
    const mutex = try Mutex.create();
    defer mutex.destroy();

    mutex.lock();
    mutex.lock(); // SDL mutexes are recursive
    mutex.unlock();
    mutex.unlock();

    const success = mutex.tryLock();
    try std.testing.expect(success); // Should be fully unlocked
    mutex.unlock();
}

test "read/write lock operations" {
    const rwlock = try RWLock.create();
    defer rwlock.destroy();

    // Test read locking
    rwlock.lockRead();
    const can_read = rwlock.tryLockRead();
    try std.testing.expect(can_read); // Multiple readers allowed
    rwlock.unlock();
    rwlock.unlock();

    // Test write locking
    rwlock.lockWrite();
    const can_write = rwlock.tryLockWrite();
    try std.testing.expect(!can_write); // No concurrent writers
    const can_read_with_writer = rwlock.tryLockRead();
    try std.testing.expect(!can_read_with_writer); // No readers with writer
    rwlock.unlock();
}

test "condition variable operations" {
    const mutex = try Mutex.create();
    defer mutex.destroy();

    const cond = try Condition.create();
    defer cond.destroy();

    // Test timeout
    mutex.lock();
    const signaled = cond.waitTimeout(&mutex, 1);
    try std.testing.expect(!signaled); // Should timeout
    mutex.unlock();

    // Test signal
    const TestContext = struct {
        mutex: *Mutex,
        cond: *Condition,
        ready: bool = false,

        fn wait(self: *@This()) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (!self.ready) {
                self.cond.wait(self.mutex);
            }
        }

        fn signal(self: *@This()) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            self.ready = true;
            self.cond.signal();
        }
    };

    var context = TestContext{
        .mutex = &mutex,
        .cond = &cond,
    };

    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            const ctx = @as(*TestContext, @ptrCast(@alignCast(data.?)));
            ctx.wait();
            return 0;
        }
    }).func;

    const thread = c.SDL_CreateThread(threadFn, "waiter", &context) orelse {
        @panic("Failed to create thread");
    };

    // Signal the waiting thread
    context.signal();

    var status: c_int = undefined;
    c.SDL_WaitThread(thread, &status);
    try std.testing.expectEqual(@as(c_int, 0), status);
}
