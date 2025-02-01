//! Audio mixing and music for SDL3.
//!
//! This module provides advanced audio features:
//! - Sound effect mixing
//! - Music playback
//! - Channel management
//! - Volume control
//! - Effect processing
//!
//! Initialization:
//! ```zig
//! // Initialize mixer
//! try mixer.init(.{
//!     .frequency = 44100,
//!     .format = .s16_sys,
//!     .channels = 2,
//!     .chunk_size = 2048,
//! });
//! defer mixer.quit();
//! ```
//!
//! Sound effects:
//! ```zig
//! // Load and play sound
//! const sound = try mixer.Chunk.load("sound.wav");
//! defer sound.free();
//!
//! const channel = try mixer.playChannel(-1, sound, 0);
//! ```
//!
//! Music playback:
//! ```zig
//! // Load and play music
//! const music = try mixer.Music.load("music.mp3");
//! defer music.free();
//!
//! try mixer.playMusic(music, -1);
//! ```
//!
//! Channel control:
//! ```zig
//! // Set volume
//! mixer.setVolume(-1, 64); // All channels
//! mixer.setMusicVolume(128);
//!
//! // Fade effects
//! try mixer.fadeOutChannel(-1, 1000);
//! try mixer.fadeOutMusic(2000);
//! ```
//!
//! Note: This module requires SDL_mixer to be installed.

pub usingnamespace @import("mixer.zig");

test {
    // Test all public modules
    _ = @import("mixer.zig");
}
