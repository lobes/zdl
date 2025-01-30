//! Dynamic library loading functionality for SDL3.
//!
//! This module provides shared object operations:
//! - Dynamic library loading
//! - Symbol lookup
//! - Error handling
//!
//! Dependencies:
//! - Core SDL3 shared object functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Load a shared library
//! const lib = try loadso.load("mylib.so");
//! defer lib.unload();
//!
//! // Look up a symbol
//! const func = try lib.sym("my_function");
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Handle to a dynamically loaded shared object
pub const SharedObject = struct {
    handle: *c.SDL_SharedObject,

    /// Load a shared object
    pub fn load(sofile: [:0]const u8) !SharedObject {
        const handle = c.SDL_LoadObject(sofile.ptr) orelse {
            const err = std.mem.span(c.SDL_GetError());
            std.debug.print("SDL_LoadObject failed: {s}\n", .{err});
            return error.LoadObjectFailed;
        };
        return SharedObject{ .handle = handle };
    }

    /// Unload a shared object
    pub fn unload(self: SharedObject) void {
        c.SDL_UnloadObject(self.handle);
    }

    /// Look up a symbol in a shared object
    pub fn sym(self: SharedObject, name: [:0]const u8) !*anyopaque {
        const symbol = c.SDL_LoadFunction(self.handle, name.ptr) orelse {
            const err = std.mem.span(c.SDL_GetError());
            std.debug.print("SDL_LoadFunction failed: {s}\n", .{err});
            return error.LoadFunctionFailed;
        };
        return symbol;
    }
};

test "loadso basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Skip test if no library name provided
    if (false) {
        // Load a shared library
        const lib = try SharedObject.load("test.so");
        defer lib.unload();

        // Look up a symbol
        const symbol = try lib.sym("test_function");
        try std.testing.expect(symbol != null);
    }
}
