//! Core functionality for SDL3.
//!
//! This module provides fundamental SDL3 features:
//! - System initialization and shutdown
//! - Event handling and processing
//! - High-resolution timing
//! - Error handling
//! - Properties system
//! - Asynchronous I/O
//! - Thread management
//! - Synchronization primitives
//! - Runtime configuration
//! - Logging system
//! - Byte order operations
//! - Version information
//!
//! Most applications will start with initialization:
//! ```zig
//! // Initialize SDL with required subsystems
//! try core.init.init(.{
//!     .video = true,
//!     .audio = true,
//! });
//! defer core.init.quit();
//! ```
//!
//! Event handling:
//! ```zig
//! var event: core.events.Event = undefined;
//! while (core.events.poll(&event)) {
//!     switch (event) {
//!         .quit => break,
//!         else => {},
//!     }
//! }
//! ```
//!
//! Timing:
//! ```zig
//! const start = core.timer.getTicks();
//! core.timer.delay(16); // 60 FPS
//! ```
//!
//! Thread management:
//! ```zig
//! const thread = try core.thread.Thread.spawn(.{}, worker, .{});
//! defer thread.join();
//! ```
//!
//! Error handling:
//! ```zig
//! const result = operation() catch |err| {
//!     core.log.err("Operation failed: {s}", .{core.errors.getError()});
//!     return err;
//! };
//! ```

pub const init = @import("init.zig");
pub const errors = @import("error.zig");
pub const events = @import("events.zig");
pub const timer = @import("timer.zig");
pub const props = @import("props.zig");
pub const async_io = @import("async.zig");
pub const thread = @import("thread.zig");
pub const atomic = @import("atomic.zig");
pub const mutex = @import("mutex.zig");
pub const hints = @import("hints.zig");
pub const semaphore = @import("semaphore.zig");
pub const log = @import("log.zig");
pub const endian = @import("endian.zig");
pub const version = @import("version.zig");

test {
    // Test all public modules
    _ = init;
    _ = errors;
    _ = events;
    _ = timer;
    _ = props;
    _ = async_io;
    _ = thread;
    _ = atomic;
    _ = mutex;
    _ = hints;
    _ = semaphore;
    _ = log;
    _ = endian;
    _ = version;
}
