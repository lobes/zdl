//! Logging system for SDL3.
//!
//! This module provides a flexible logging and message routing system:
//! - Multiple log priority levels
//! - Category-based filtering
//! - Custom output routing
//! - Thread-safe logging operations
//! - Output formatting control
//!
//! Dependencies:
//! - Core SDL3 logging system
//! - Uses error.zig for error handling
//!
//! Thread safety: All logging operations are thread-safe. Multiple threads can
//! safely write to the log simultaneously.
//!
//! Memory management: Log messages are copied internally. Category strings must
//! remain valid for the duration of the program if used in category callbacks.
//!
//! Example:
//! ```zig
//! // Set log priority
//! log.setPriority(.info);
//!
//! // Log messages at different levels
//! log.debug("Debug message");
//! log.info("Info message");
//! log.warn("Warning message");
//! log.error("Error message");
//!
//! // Use categories
//! log.message(.info, "Render", "Frame rendered in {d}ms", .{16});
//!
//! // Custom output function
//! try log.setOutputFunction(myOutputFn, myUserData);
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const core = @import("../core/module.zig");
const errors = core.errors;

/// Log priority levels
pub const Priority = enum {
    verbose,
    debug,
    info,
    warn,
    error_,
    critical,
};

/// Convert Priority to SDL_LogPriority
fn priorityToSDL(priority: Priority) c.SDL_LogPriority {
    return switch (priority) {
        .verbose => c.SDL_LOG_PRIORITY_VERBOSE,
        .debug => c.SDL_LOG_PRIORITY_DEBUG,
        .info => c.SDL_LOG_PRIORITY_INFO,
        .warn => c.SDL_LOG_PRIORITY_WARN,
        .error_ => c.SDL_LOG_PRIORITY_ERROR,
        .critical => c.SDL_LOG_PRIORITY_CRITICAL,
    };
}

/// Convert SDL_LogPriority to Priority
fn priorityFromSDL(priority: c.SDL_LogPriority) Priority {
    return switch (priority) {
        c.SDL_LOG_PRIORITY_VERBOSE => .verbose,
        c.SDL_LOG_PRIORITY_DEBUG => .debug,
        c.SDL_LOG_PRIORITY_INFO => .info,
        c.SDL_LOG_PRIORITY_WARN => .warn,
        c.SDL_LOG_PRIORITY_ERROR => .error_,
        c.SDL_LOG_PRIORITY_CRITICAL => .critical,
        else => .info,
    };
}

/// Log categories for message filtering
pub const Category = enum {
    application,
    error_,
    system,
    audio,
    video,
    render,
    input,
    custom,
};

/// Convert Category to SDL_LogCategory
fn categoryToSDL(category: Category) c_int {
    return switch (category) {
        .application => c.SDL_LOG_CATEGORY_APPLICATION,
        .error_ => c.SDL_LOG_CATEGORY_ERROR,
        .system => c.SDL_LOG_CATEGORY_SYSTEM,
        .audio => c.SDL_LOG_CATEGORY_AUDIO,
        .video => c.SDL_LOG_CATEGORY_VIDEO,
        .render => c.SDL_LOG_CATEGORY_RENDER,
        .input => c.SDL_LOG_CATEGORY_INPUT,
        .custom => c.SDL_LOG_CATEGORY_CUSTOM,
    };
}

/// Convert SDL_LogCategory to Category
fn categoryFromSDL(category: c_int) Category {
    return switch (category) {
        c.SDL_LOG_CATEGORY_APPLICATION => .application,
        c.SDL_LOG_CATEGORY_ERROR => .error_,
        c.SDL_LOG_CATEGORY_SYSTEM => .system,
        c.SDL_LOG_CATEGORY_AUDIO => .audio,
        c.SDL_LOG_CATEGORY_VIDEO => .video,
        c.SDL_LOG_CATEGORY_RENDER => .render,
        c.SDL_LOG_CATEGORY_INPUT => .input,
        c.SDL_LOG_CATEGORY_CUSTOM => .custom,
        else => .application,
    };
}

/// Function type for custom log output
pub const OutputFn = *const fn (
    userdata: ?*anyopaque,
    category: Category,
    priority: Priority,
    message: [*:0]const u8,
) void;

/// Set the priority level for all categories
pub fn setPriority(priority: Priority) void {
    c.SDL_LogSetAllPriority(priorityToSDL(priority));
}

/// Set the priority level for a specific category
pub fn setCategoryPriority(category: Category, priority: Priority) void {
    c.SDL_LogSetPriority(categoryToSDL(category), priorityToSDL(priority));
}

/// Get the priority level for a specific category
pub fn getCategoryPriority(category: Category) Priority {
    return priorityFromSDL(c.SDL_LogGetPriority(categoryToSDL(category)));
}

/// Reset all priorities to default
pub fn resetPriorities() void {
    c.SDL_LogResetPriorities();
}

/// Log a message with the specified priority and category
pub fn message(priority: Priority, category: []const u8, comptime fmt: []const u8, args: anytype) void {
    const msg = std.fmt.allocPrint(std.heap.c_allocator, fmt, args) catch return;
    defer std.heap.c_allocator.free(msg);
    c.SDL_LogMessage(categoryToSDL(.custom), priorityToSDL(priority), "%s: %s", category.ptr, msg.ptr);
}

/// Log a debug message
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    message(.debug, "Debug", fmt, args);
}

/// Log an info message
pub fn info(comptime fmt: []const u8, args: anytype) void {
    message(.info, "Info", fmt, args);
}

/// Log a warning message
pub fn warn(comptime fmt: []const u8, args: anytype) void {
    message(.warn, "Warning", fmt, args);
}

/// Log an error message
pub fn logError(comptime fmt: []const u8, args: anytype) void {
    message(.error_, "Error", fmt, args);
}

/// Log a critical message
pub fn critical(comptime fmt: []const u8, args: anytype) void {
    message(.critical, "Critical", fmt, args);
}

/// Set a custom output function for log messages
pub fn setOutputFunction(callback: OutputFn, userdata: ?*anyopaque) void {
    c.SDL_LogSetOutputFunction(
        @ptrCast(callback),
        userdata,
    );
}

/// Get the current output function and userdata
pub fn getOutputFunction() struct { callback: OutputFn, userdata: ?*anyopaque } {
    var callback: c.SDL_LogOutputFunction = undefined;
    var userdata: ?*anyopaque = undefined;
    c.SDL_LogGetOutputFunction(&callback, &userdata);
    return .{
        .callback = @ptrCast(callback),
        .userdata = userdata,
    };
}

test "log priorities" {
    // Test setting and getting priorities
    setPriority(.info);
    setCategoryPriority(.render, .debug);
    try std.testing.expectEqual(Priority.debug, getCategoryPriority(.render));

    // Reset priorities
    resetPriorities();
    try std.testing.expectEqual(Priority.info, getCategoryPriority(.render));
}

test "log messages" {
    // Test basic logging
    debug("Test debug message: {s}", .{"hello"});
    info("Test info message: {d}", .{42});
    warn("Test warning message: {any}", .{true});
    logError("Test error message: {x}", .{0xFF});
    critical("Test critical message: {c}", .{'!'});

    // Test custom category message
    message(.info, "Test", "Custom category message: {s}", .{"test"});
}

test "log output function" {
    const Context = struct {
        last_message: []const u8 = "",
        allocator: std.mem.Allocator,

        fn onLog(
            userdata: ?*anyopaque,
            category: Category,
            priority: Priority,
            message: [*:0]const u8,
        ) void {
            const self = @as(*@This(), @ptrCast(@alignCast(userdata.?)));
            if (self.last_message.len > 0) {
                self.allocator.free(self.last_message);
            }
            self.last_message = std.mem.span(message);
            _ = category;
            _ = priority;
        }
    };

    var ctx = Context{ .allocator = std.testing.allocator };
    try setOutputFunction(Context.onLog, &ctx);
    defer if (ctx.last_message.len > 0) {
        ctx.allocator.free(ctx.last_message);
    }

    // Test that our output function receives messages
    const test_message = "Test output function";
    info("{s}", .{test_message});
    try std.testing.expect(std.mem.indexOf(u8, ctx.last_message, test_message) != null);

    // Verify we can get the output function back
    const output = getOutputFunction();
    try std.testing.expectEqual(@as(OutputFn, Context.onLog), output.callback);
    try std.testing.expectEqual(@as(?*anyopaque, &ctx), output.userdata);
} 