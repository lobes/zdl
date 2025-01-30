//! Audio functionality for SDL3.
//!
//! This module provides audio capabilities:
//! - Audio device management
//! - Audio playback and capture
//! - Format conversion
//! - Stream handling
//! - Device enumeration
//!
//! Basic audio playback:
//! ```zig
//! // Open audio device
//! var spec = audio.AudioSpec{
//!     .freq = 44100,
//!     .format = .f32_sys,
//!     .channels = 2,
//!     .samples = 4096,
//!     .callback = audioCallback,
//! };
//! const device = try audio.openDevice(null, false, &spec, null);
//! defer device.close();
//!
//! // Start playback
//! device.pause(false);
//! ```
//!
//! Audio format conversion:
//! ```zig
//! // Convert between formats
//! const dst = try audio.convert(.u16_sys, .u8, src_data);
//! defer audio.free(dst);
//! ```
//!
//! Device enumeration:
//! ```zig
//! // List audio devices
//! const num_output = audio.getNumDevices(false);
//! const num_input = audio.getNumDevices(true);
//!
//! if (audio.getDeviceName(0, false)) |name| {
//!     // Found output device
//! }
//! ```

pub const audio = @import("audio.zig");

test {
    // Test all public modules
    _ = audio;
}
