//! Byte order operations for SDL3.
//!
//! This module provides byte swapping and endianness utilities:
//! - Native endian detection
//! - Byte order swapping
//! - Multi-byte value conversion
//! - Stream byte order handling
//!
//! Dependencies:
//! - Core SDL3 endian functionality
//!
//! Thread safety: All operations are pure functions with no side effects
//! and are safe to use from multiple threads.
//!
//! Memory management: No dynamic memory allocation is used.
//!
//! Example:
//! ```zig
//! // Swap bytes if needed
//! const native_value = endian.swapIfBE(u32, raw_value);
//!
//! // Convert to network byte order (big endian)
//! const network_value = endian.hostToBE(u16, host_value);
//!
//! // Convert from network byte order
//! const host_value = endian.BEToHost(u32, network_value);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

/// Byte order enumeration
pub const ByteOrder = enum {
    little,
    big,
    native,
};

/// Get the native byte order of the system
pub fn getNativeByteOrder() ByteOrder {
    return if (c.SDL_BYTEORDER == c.SDL_LIL_ENDIAN)
        .little
    else
        .big;
}

/// Check if the system is little endian
pub fn isLittleEndian() bool {
    return getNativeByteOrder() == .little;
}

/// Check if the system is big endian
pub fn isBigEndian() bool {
    return getNativeByteOrder() == .big;
}

/// Swap bytes of a 16-bit value
pub fn swap16(x: u16) u16 {
    return c.SDL_Swap16(x);
}

/// Swap bytes of a 32-bit value
pub fn swap32(x: u32) u32 {
    return c.SDL_Swap32(x);
}

/// Swap bytes of a 64-bit value
pub fn swap64(x: u64) u64 {
    return c.SDL_Swap64(x);
}

/// Swap bytes of a float value
pub fn swapFloat(x: f32) f32 {
    const bits = @as(u32, @bitCast(x));
    const swapped = swap32(bits);
    return @as(f32, @bitCast(swapped));
}

/// Convert host byte order to little endian
pub fn hostToLE(comptime T: type, x: T) T {
    return switch (T) {
        u16 => if (isLittleEndian()) x else swap16(x),
        u32 => if (isLittleEndian()) x else swap32(x),
        u64 => if (isLittleEndian()) x else swap64(x),
        f32 => if (isLittleEndian()) x else swapFloat(x),
        else => @compileError("Unsupported type for byte swapping"),
    };
}

/// Convert host byte order to big endian
pub fn hostToBE(comptime T: type, x: T) T {
    return switch (T) {
        u16 => if (isBigEndian()) x else swap16(x),
        u32 => if (isBigEndian()) x else swap32(x),
        u64 => if (isBigEndian()) x else swap64(x),
        f32 => if (isBigEndian()) x else swapFloat(x),
        else => @compileError("Unsupported type for byte swapping"),
    };
}

/// Convert little endian to host byte order
pub fn LEToHost(comptime T: type, x: T) T {
    return hostToLE(T, x); // Same operation as host to LE
}

/// Convert big endian to host byte order
pub fn BEToHost(comptime T: type, x: T) T {
    return hostToBE(T, x); // Same operation as host to BE
}

/// Swap bytes if system is little endian
pub fn swapIfLE(comptime T: type, x: T) T {
    return if (isLittleEndian()) switch (T) {
        u16 => swap16(x),
        u32 => swap32(x),
        u64 => swap64(x),
        f32 => swapFloat(x),
        else => @compileError("Unsupported type for byte swapping"),
    } else x;
}

/// Swap bytes if system is big endian
pub fn swapIfBE(comptime T: type, x: T) T {
    return if (isBigEndian()) switch (T) {
        u16 => swap16(x),
        u32 => swap32(x),
        u64 => swap64(x),
        f32 => swapFloat(x),
        else => @compileError("Unsupported type for byte swapping"),
    } else x;
}

const testing = @import("std").testing;

test "native byte order" {
    const order = getNativeByteOrder();
    try testing.expect(order == .little or order == .big);
    try testing.expect(isLittleEndian() != isBigEndian());
}

test "byte swapping" {
    // Test 16-bit swap
    try testing.expectEqual(@as(u16, 0x3412), swap16(0x1234));

    // Test 32-bit swap
    try testing.expectEqual(@as(u32, 0x78563412), swap32(0x12345678));

    // Test 64-bit swap
    try testing.expectEqual(
        @as(u64, 0x8877665544332211),
        swap64(0x1122334455667788),
    );

    // Test float swap
    const original: f32 = 123.456;
    const swapped = swapFloat(original);
    const restored = swapFloat(swapped);
    try testing.expectEqual(original, restored);
}

test "endian conversion" {
    const value16: u16 = 0x1234;
    const value32: u32 = 0x12345678;
    const value64: u64 = 0x1122334455667788;
    const valuef32: f32 = 123.456;

    // Test LE conversion
    const le16 = hostToLE(u16, value16);
    try testing.expectEqual(value16, LEToHost(u16, le16));

    const le32 = hostToLE(u32, value32);
    try testing.expectEqual(value32, LEToHost(u32, le32));

    const le64 = hostToLE(u64, value64);
    try testing.expectEqual(value64, LEToHost(u64, le64));

    const lef32 = hostToLE(f32, valuef32);
    try testing.expectEqual(valuef32, LEToHost(f32, lef32));

    // Test BE conversion
    const be16 = hostToBE(u16, value16);
    try testing.expectEqual(value16, BEToHost(u16, be16));

    const be32 = hostToBE(u32, value32);
    try testing.expectEqual(value32, BEToHost(u32, be32));

    const be64 = hostToBE(u64, value64);
    try testing.expectEqual(value64, BEToHost(u64, be64));

    const bef32 = hostToBE(f32, valuef32);
    try testing.expectEqual(valuef32, BEToHost(f32, bef32));
}

test "conditional swapping" {
    const value: u32 = 0x12345678;
    const swapped: u32 = 0x78563412;

    // One of these should be equal to the original, one should be swapped
    const le_swap = swapIfLE(u32, value);
    const be_swap = swapIfBE(u32, value);

    if (isLittleEndian()) {
        try testing.expectEqual(swapped, le_swap);
        try testing.expectEqual(value, be_swap);
    } else {
        try testing.expectEqual(value, le_swap);
        try testing.expectEqual(swapped, be_swap);
    }
}
