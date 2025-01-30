//! Sensor functionality for SDL3.
//!
//! This module provides access to device sensors:
//! - Accelerometer
//! - Gyroscope
//! - Orientation sensors
//! - Sensor event handling
//!
//! Dependencies:
//! - Core SDL3 sensor functionality
//!
//! Thread safety: All operations should be performed from the main thread.
//!
//! Example:
//! ```zig
//! // Open accelerometer
//! const sensor = try sensor.open(.accelerometer);
//! defer sensor.close();
//!
//! // Get sensor data
//! const data = try sensor.getData();
//! std.debug.print("Acceleration: x={d} y={d} z={d}\n", .{
//!     data[0], data[1], data[2]
//! });
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const core = @import("../core/module.zig");
const errors = core.errors;

/// Types of sensors
pub const SensorType = enum(i32) {
    invalid = c.SDL_SENSOR_INVALID,
    unknown = c.SDL_SENSOR_UNKNOWN,
    accelerometer = c.SDL_SENSOR_ACCEL,
    gyroscope = c.SDL_SENSOR_GYRO,
};

/// Sensor device handle
pub const Sensor = struct {
    handle: *c.SDL_Sensor,

    /// Open a sensor for the given type
    pub fn open(sensor_type: SensorType) !Sensor {
        const handle = c.SDL_SensorOpen(@intFromEnum(sensor_type)) orelse return error.SensorOpenFailed;
        return Sensor{ .handle = handle };
    }

    /// Close a sensor
    pub fn close(self: Sensor) void {
        c.SDL_SensorClose(self.handle);
    }

    /// Get the current state of a sensor
    pub fn getData(self: Sensor) ![6]f32 {
        var data: [6]f32 = undefined;
        if (!c.SDL_SensorGetData(self.handle, &data, 6)) {
            return error.SensorGetDataFailed;
        }
        return data;
    }

    /// Get the instance ID of a sensor
    pub fn getInstance(self: Sensor) i32 {
        return c.SDL_SensorGetInstanceID(self.handle);
    }

    /// Get the type of a sensor
    pub fn getType(self: Sensor) SensorType {
        return @enumFromInt(c.SDL_SensorGetType(self.handle));
    }

    /// Get the platform dependent name of a sensor
    pub fn getName(self: Sensor) ?[:0]const u8 {
        const name = c.SDL_SensorGetName(self.handle) orelse return null;
        return std.mem.span(name);
    }
};

/// Get the number of sensors
pub fn numSensors() i32 {
    return c.SDL_NumSensors();
}

/// Get the type of a sensor
pub fn getSensorTypeFromInstance(instance_id: i32) SensorType {
    return @enumFromInt(c.SDL_SensorGetTypeFromInstanceID(instance_id));
}

/// Get the platform dependent name of a sensor
pub fn getSensorNameFromInstance(instance_id: i32) ?[:0]const u8 {
    const name = c.SDL_SensorGetNameFromInstanceID(instance_id) orelse return null;
    return std.mem.span(name);
}

/// Update the current state of the open sensors
pub fn update() void {
    c.SDL_SensorUpdate();
}

test "sensor basics" {
    try core.init.init(.{ .sensor = true });
    defer core.init.quit();

    // Get number of sensors
    const num = numSensors();
    try std.testing.expect(num >= 0);

    // Skip test if no sensors
    if (num == 0) return;

    // Try to open accelerometer
    const sensor = Sensor.open(.accelerometer) catch |err| switch (err) {
        error.SensorOpenFailed => return, // Skip if no accelerometer
        else => return err,
    };
    defer sensor.close();

    // Get sensor info
    const name = sensor.getName();
    if (name) |n| try std.testing.expect(n.len > 0);

    const type_id = sensor.getType();
    try std.testing.expectEqual(SensorType.accelerometer, type_id);

    const instance = sensor.getInstance();
    try std.testing.expect(instance >= 0);

    // Update sensors
    update();

    // Try to get data
    const data = sensor.getData() catch |err| switch (err) {
        error.SensorGetDataFailed => return, // Skip if can't get data
        else => return err,
    };
    try std.testing.expect(data.len == 6);
}
