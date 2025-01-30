//! Thread management and synchronization primitives for SDL3.
//!
//! This module provides cross-platform thread management:
//! - Thread creation and management
//! - Thread priority control
//! - Thread Local Storage (TLS)
//! - Thread naming and identification
//!
//! Thread safety: This module is thread-safe and designed for concurrent use.
//! Memory management: Thread resources are automatically cleaned up when the thread exits.
//!
//! Example:
//! ```zig
//! const thread = try Thread.spawn("worker", workerFn, context);
//! defer thread.detach();
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const errors = @import("error.zig");

/// Function type for thread entry points
pub const ThreadFn = *const fn (data: ?*anyopaque) callconv(.C) c_int;

/// Thread priority levels
pub const ThreadPriority = enum(c_int) {
    low = c.SDL_THREAD_PRIORITY_LOW,
    normal = c.SDL_THREAD_PRIORITY_NORMAL,
    high = c.SDL_THREAD_PRIORITY_HIGH,
    time_critical = c.SDL_THREAD_PRIORITY_TIME_CRITICAL,
};

/// A handle to a thread
pub const Thread = struct {
    handle: *c.SDL_Thread,

    /// Create a new thread
    pub fn spawn(name: [*:0]const u8, fn_ptr: ThreadFn, data: ?*anyopaque) !Thread {
        const handle = c.SDL_CreateThread(fn_ptr, name, data) orelse {
            return errors.sdlError();
        };
        return Thread{ .handle = handle };
    }

    /// Wait for a thread to finish execution
    pub fn join(self: Thread) !c_int {
        var status: c_int = undefined;
        c.SDL_WaitThread(self.handle, &status);
        return status;
    }

    /// Let a thread run independently of the parent
    pub fn detach(self: *const Thread) void {
        c.SDL_DetachThread(self.handle);
    }

    /// Set thread priority
    pub fn setPriority(priority: ThreadPriority) !void {
        if (!c.SDL_SetThreadPriority(@intFromEnum(priority))) {
            return errors.sdlError();
        }
    }

    /// Get the thread name
    pub fn getName(self: Thread) ?[*:0]const u8 {
        return c.SDL_GetThreadName(self.handle);
    }

    /// Get the thread ID
    pub fn getId(self: Thread) u64 {
        return c.SDL_GetThreadID(self.handle);
    }
};

/// Thread Local Storage key
pub const TLS = struct {
    id: c.SDL_TLSID,

    /// Create a new TLS key
    pub fn create() !TLS {
        const id = c.SDL_CreateTLS() orelse {
            return errors.sdlError();
        };
        return TLS{ .id = id };
    }

    /// Set a TLS value
    pub fn set(self: TLS, value: ?*anyopaque) !void {
        if (!c.SDL_SetTLS(self.id, value)) {
            return errors.sdlError();
        }
    }

    /// Get a TLS value
    pub fn get(self: TLS) ?*anyopaque {
        return c.SDL_GetTLS(self.id);
    }

    /// Destroy a TLS key
    pub fn destroy(self: *TLS) void {
        c.SDL_DestroyTLS(self.id);
        self.* = undefined;
    }
};

test "thread creation and joining" {
    const TestContext = struct {
        value: i32 = 42,
    };

    var context = TestContext{};

    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            const ctx = @as(*TestContext, @ptrCast(@alignCast(data.?)));
            return ctx.value;
        }
    }).func;

    const thread = try Thread.spawn("test", threadFn, &context);
    const result = try thread.join();
    try std.testing.expectEqual(@as(c_int, 42), result);
}

test "thread priority" {
    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            _ = data;
            return 0;
        }
    }).func;

    const thread = try Thread.spawn("priority_test", threadFn, null);
    try Thread.setPriority(.high);
    _ = try thread.join();
}

test "thread local storage" {
    const tls = try TLS.create();
    defer tls.destroy();

    var value: i32 = 123;
    try tls.set(&value);

    const retrieved = @as(*i32, @ptrCast(@alignCast(tls.get().?)));
    try std.testing.expectEqual(@as(i32, 123), retrieved.*);
}

test "thread name and id" {
    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            _ = data;
            return 0;
        }
    }).func;

    const thread = try Thread.spawn("name_test", threadFn, null);
    const name = thread.getName();
    try std.testing.expectEqualStrings("name_test", std.mem.span(name.?));
    _ = try thread.join();
}

test "multiple threads" {
    const TestContext = struct {
        counter: std.atomic.Atomic(u32),

        fn init() @This() {
            return .{
                .counter = std.atomic.Atomic(u32).init(0),
            };
        }
    };

    var context = TestContext.init();

    const threadFn = (struct {
        fn func(data: ?*anyopaque) callconv(.C) c_int {
            const ctx = @as(*TestContext, @ptrCast(@alignCast(data.?)));
            _ = ctx.counter.fetchAdd(1, .Monotonic);
            return 0;
        }
    }).func;

    var threads: [4]Thread = undefined;
    for (&threads) |*t| {
        t.* = try Thread.spawn("worker", threadFn, &context);
    }

    for (threads) |t| {
        _ = try t.join();
    }

    try std.testing.expectEqual(@as(u32, 4), context.counter.load(.Monotonic));
}
