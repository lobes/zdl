//! Asynchronous I/O operations for SDL3.
//!
//! This module provides non-blocking I/O operations for file access:
//! - Async file open/close
//! - Async read/write operations
//! - Task queuing and management
//! - Result handling and status tracking
//!
//! Dependencies:
//! - Requires SDL3 with async I/O support
//! - Uses error.zig for error handling
//!
//! Thread safety: Operations are thread-safe. Multiple threads can safely queue
//! operations to the same async queue, but task results should be handled by
//! the thread that initiated the operation.
//!
//! Memory management: Tasks are automatically cleaned up when completed. Files
//! must be explicitly closed when no longer needed.
//!
//! Example:
//! ```zig
//! const queue = try Queue.create();
//! defer queue.destroy();
//!
//! var file = try File.open("data.txt", "rb");
//! var buffer: [1024]u8 = undefined;
//! const task = try file.read(queue, &buffer);
//!
//! const result = try queue.waitForResult();
//! if (result.isSuccess()) {
//!     const bytes_read = result.getSize();
//!     // Process data...
//! }
//! ```

const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const core = @import("../core/module.zig");
const errors = core.errors;

/// A queue that holds async I/O tasks
pub const Queue = struct {
    handle: *c.SDL_AsyncIOQueue,

    /// Create a new async I/O queue
    pub fn create() !Queue {
        const handle = c.SDL_CreateAsyncIOQueue() orelse {
            return errors.sdlError();
        };
        return Queue{ .handle = handle };
    }

    /// Destroy an async I/O queue
    pub fn destroy(self: *Queue) void {
        c.SDL_DestroyAsyncIOQueue(self.handle);
        self.* = undefined;
    }

    /// Get the result of a completed task from the queue without blocking
    pub fn getResult(self: Queue) ?TaskResult {
        var result: c.SDL_AsyncIOResult = undefined;
        if (c.SDL_GetAsyncIOResult(self.handle, &result)) {
            return TaskResult{
                .task = result.task,
                .status = result.status,
                .size = result.size,
            };
        }
        return null;
    }

    /// Wait for a task to complete and return its result
    pub fn waitForResult(self: Queue) !TaskResult {
        var result: c.SDL_AsyncIOResult = undefined;
        if (!c.SDL_WaitAsyncIOResult(self.handle, &result)) {
            return errors.sdlError();
        }
        return TaskResult{
            .task = result.task,
            .status = result.status,
            .size = result.size,
        };
    }
};

/// A handle to an async I/O file
pub const File = struct {
    handle: *c.SDL_AsyncIO,

    /// Open a file for async I/O operations
    pub fn open(path: [*:0]const u8, mode: [*:0]const u8) !File {
        const handle = c.SDL_AsyncIOFromFile(path, mode) orelse {
            return errors.sdlError();
        };
        return File{ .handle = handle };
    }

    /// Start an async read operation
    pub fn read(self: File, queue: Queue, buffer: []u8) !*c.SDL_AsyncIOTask {
        const task = c.SDL_ReadAsyncIO(queue.handle, self.handle, buffer.ptr, buffer.len) orelse {
            return errors.sdlError();
        };
        return task;
    }

    /// Start an async write operation
    pub fn write(self: File, queue: Queue, data: []const u8) !*c.SDL_AsyncIOTask {
        const task = c.SDL_WriteAsyncIO(queue.handle, self.handle, data.ptr, data.len) orelse {
            return errors.sdlError();
        };
        return task;
    }

    /// Close the file asynchronously
    pub fn close(self: *File, queue: Queue) !*c.SDL_AsyncIOTask {
        const task = c.SDL_CloseAsyncIO(queue.handle, self.handle) orelse {
            return errors.sdlError();
        };
        self.* = undefined;
        return task;
    }
};

/// The result of an async I/O task
pub const TaskResult = struct {
    task: *c.SDL_AsyncIOTask,
    status: i32,
    size: usize,

    /// Check if the task completed successfully
    pub fn isSuccess(self: TaskResult) bool {
        return self.status >= 0;
    }

    /// Get the number of bytes transferred
    pub fn getSize(self: TaskResult) usize {
        return self.size;
    }
};

test "async queue creation and destruction" {
    var queue = try Queue.create();
    defer queue.destroy();
}

test "async file operations" {
    var queue = try Queue.create();
    defer queue.destroy();

    // Create a test file
    {
        var file = try std.fs.cwd().createFile("test.txt", .{});
        defer file.close();
        _ = try file.write("Hello, Async I/O!");
    }

    // Open the file asynchronously
    var file = try File.open("test.txt", "rb");

    // Read the file content
    var buffer: [100]u8 = undefined;
    const read_task = try file.read(queue, &buffer);

    // Wait for the read to complete
    const result = try queue.waitForResult();
    try std.testing.expect(result.task == read_task);
    try std.testing.expect(result.isSuccess());
    try std.testing.expect(result.getSize() == 15); // Length of "Hello, Async I/O!"

    // Close the file
    const close_task = try file.close(queue);
    const close_result = try queue.waitForResult();
    try std.testing.expect(close_result.task == close_task);
    try std.testing.expect(close_result.isSuccess());

    // Clean up the test file
    try std.fs.cwd().deleteFile("test.txt");
}

test "async write operation" {
    var queue = try Queue.create();
    defer queue.destroy();

    var file = try File.open("test_write.txt", "wb");

    const data = "Testing async write!";
    const write_task = try file.write(queue, data);

    const result = try queue.waitForResult();
    try std.testing.expect(result.task == write_task);
    try std.testing.expect(result.isSuccess());
    try std.testing.expect(result.getSize() == data.len);

    const close_task = try file.close(queue);
    const close_result = try queue.waitForResult();
    try std.testing.expect(close_result.task == close_task);
    try std.testing.expect(close_result.isSuccess());

    // Verify the written content
    const written = try std.fs.cwd().readFileAlloc(std.testing.allocator, "test_write.txt", 1024);
    defer std.testing.allocator.free(written);
    try std.testing.expectEqualStrings(data, written);

    // Clean up
    try std.fs.cwd().deleteFile("test_write.txt");
}
