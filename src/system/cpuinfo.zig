//! CPU information functionality for SDL3.
//!
//! This module provides CPU feature detection:
//! - CPU feature testing
//! - Core counting
//! - Cache information
//!
//! Dependencies:
//! - Core SDL3 CPU information functionality
//!
//! Thread safety: All operations are thread-safe.
//!
//! Example:
//! ```zig
//! // Get CPU info
//! const cores = cpuinfo.getCPUCount();
//! const cache = cpuinfo.getCPUCacheLineSize();
//! const has_avx = cpuinfo.hasAVX();
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Get the number of CPU cores available
pub fn getCPUCount() i32 {
    return c.SDL_GetCPUCount();
}

/// Get the L1 cache line size of the CPU
pub fn getCPUCacheLineSize() i32 {
    return c.SDL_GetCPUCacheLineSize();
}

/// Get the amount of RAM configured in the system
pub fn getSystemRAM() i32 {
    return c.SDL_GetSystemRAM();
}

/// Determine whether the CPU has the RDTSC instruction
pub fn hasRDTSC() bool {
    return c.SDL_HasRDTSC() == c.SDL_TRUE;
}

/// Determine whether the CPU has AltiVec features
pub fn hasAltiVec() bool {
    return c.SDL_HasAltiVec() == c.SDL_TRUE;
}

/// Determine whether the CPU has MMX features
pub fn hasMMX() bool {
    return c.SDL_HasMMX() == c.SDL_TRUE;
}

/// Determine whether the CPU has 3DNow! features
pub fn has3DNow() bool {
    return c.SDL_Has3DNow() == c.SDL_TRUE;
}

/// Determine whether the CPU has SSE features
pub fn hasSSE() bool {
    return c.SDL_HasSSE() == c.SDL_TRUE;
}

/// Determine whether the CPU has SSE2 features
pub fn hasSSE2() bool {
    return c.SDL_HasSSE2() == c.SDL_TRUE;
}

/// Determine whether the CPU has SSE3 features
pub fn hasSSE3() bool {
    return c.SDL_HasSSE3() == c.SDL_TRUE;
}

/// Determine whether the CPU has SSE4.1 features
pub fn hasSSE41() bool {
    return c.SDL_HasSSE41() == c.SDL_TRUE;
}

/// Determine whether the CPU has SSE4.2 features
pub fn hasSSE42() bool {
    return c.SDL_HasSSE42() == c.SDL_TRUE;
}

/// Determine whether the CPU has AVX features
pub fn hasAVX() bool {
    return c.SDL_HasAVX() == c.SDL_TRUE;
}

/// Determine whether the CPU has AVX2 features
pub fn hasAVX2() bool {
    return c.SDL_HasAVX2() == c.SDL_TRUE;
}

/// Determine whether the CPU has AVX-512F (foundation) features
pub fn hasAVX512F() bool {
    return c.SDL_HasAVX512F() == c.SDL_TRUE;
}

/// Determine whether the CPU has ARM SIMD (ARMv6) features
pub fn hasARMSIMD() bool {
    return c.SDL_HasARMSIMD() == c.SDL_TRUE;
}

/// Determine whether the CPU has NEON (ARM SIMD) features
pub fn hasNEON() bool {
    return c.SDL_HasNEON() == c.SDL_TRUE;
}

/// Determine whether the CPU has LSX (LOONGARCH SIMD) features
pub fn hasLSX() bool {
    return c.SDL_HasLSX() == c.SDL_TRUE;
}

/// Determine whether the CPU has LASX (LOONGARCH SIMD) features
pub fn hasLASX() bool {
    return c.SDL_HasLASX() == c.SDL_TRUE;
}

test "cpuinfo basics" {
    try core.init.init(.{});
    defer core.init.quit();

    // Get CPU info
    const cores = getCPUCount();
    try std.testing.expect(cores > 0);

    const cache = getCPUCacheLineSize();
    try std.testing.expect(cache > 0);

    const ram = getSystemRAM();
    try std.testing.expect(ram > 0);

    // Test CPU features
    _ = hasRDTSC();
    _ = hasAltiVec();
    _ = hasMMX();
    _ = has3DNow();
    _ = hasSSE();
    _ = hasSSE2();
    _ = hasSSE3();
    _ = hasSSE41();
    _ = hasSSE42();
    _ = hasAVX();
    _ = hasAVX2();
    _ = hasAVX512F();
    _ = hasARMSIMD();
    _ = hasNEON();
    _ = hasLSX();
    _ = hasLASX();
}
