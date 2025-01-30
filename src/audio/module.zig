//! Audio functionality for SDL3.
//!
//! This module will provide comprehensive audio support:
//! - Audio device management
//! - Format conversion
//! - Audio callbacks
//! - Stream handling
//!
//! Dependencies:
//! - Core SDL3 audio functionality
//!
//! Thread safety: Audio callbacks can be called from any thread.
//! Device management should be done from the main thread.

const audio = @import("audio.zig");

comptime {
    _ = audio;
}
