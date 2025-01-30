//! System integration for SDL3.
//!
//! This module provides system-level functionality:
//! - Message boxes and dialogs
//! - Clipboard operations
//! - Platform detection
//! - Power management
//! - File system access
//! - Dynamic library loading
//! - CPU feature detection
//!
//! Each feature has its own submodule:
//!
//! Message boxes:
//! ```zig
//! // Show simple message box
//! try system.messagebox.show(.info, "Title", "Message", null);
//! ```
//!
//! Clipboard:
//! ```zig
//! // Copy text to clipboard
//! try system.clipboard.setText("Hello SDL3!");
//! ```
//!
//! Platform info:
//! ```zig
//! // Get system info
//! const platform = system.platform.getName();
//! const ram = system.platform.getSystemRAM();
//! ```
//!
//! Power management:
//! ```zig
//! // Get battery status
//! var secs: i32 = undefined;
//! var pct: i32 = undefined;
//! const state = system.power.getInfo(&secs, &pct);
//! ```
//!
//! File system:
//! ```zig
//! // Get application paths
//! const base = try system.filesystem.getBasePath();
//! const pref = try system.filesystem.getPrefPath("org", "app");
//! ```
//!
//! Dynamic libraries:
//! ```zig
//! // Load shared library
//! const lib = try system.loadso.SharedObject.load("lib.so");
//! const sym = try lib.sym("function");
//! ```
//!
//! CPU features:
//! ```zig
//! // Check CPU capabilities
//! const cores = system.cpuinfo.getCPUCount();
//! const has_avx = system.cpuinfo.hasAVX();
//! ```

pub const messagebox = @import("messagebox.zig");
pub const clipboard = @import("clipboard.zig");
pub const platform = @import("platform.zig");
pub const power = @import("power.zig");
pub const filesystem = @import("filesystem.zig");
pub const loadso = @import("loadso.zig");
pub const cpuinfo = @import("cpuinfo.zig");

test {
    // Test all public modules
    _ = messagebox;
    _ = clipboard;
    _ = platform;
    _ = power;
    _ = filesystem;
    _ = loadso;
    _ = cpuinfo;
}
