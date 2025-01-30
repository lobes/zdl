//! Core SDL3 functionality including initialization, events, timing, and basic services.
//!
//! This module provides the fundamental building blocks for SDL3 applications:
//! - System initialization and shutdown
//! - Event handling and processing
//! - High-resolution timing
//! - Error handling
//! - Properties system
//! - Asynchronous I/O
//! - Thread management and synchronization
//!
//! Most applications will need to use this module as it provides essential functionality.
//! Other modules typically depend on the services provided here.

pub const init = @import("init.zig");
pub const errors = @import("error.zig");
pub const events = @import("events.zig");
pub const timer = @import("timer.zig");
pub const props = @import("props.zig");
pub const async_io = @import("async.zig");
pub const thread = @import("thread.zig");
pub const atomic = @import("atomic.zig");
pub const mutex = @import("mutex.zig");

comptime {
    // Import and test all core modules
    _ = init;
    _ = errors;
    _ = events;
    _ = timer;
    _ = props;
    _ = async_io;
    _ = thread;
    _ = atomic;
    _ = mutex;
}
