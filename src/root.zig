const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

pub const init = @import("init.zig");
pub const video = @import("video.zig");
pub const render = @import("render.zig");
pub const events = @import("events.zig");
pub const rect = @import("rect.zig");
pub const pixels = @import("pixels.zig");
pub const surface = @import("surface.zig");
pub const timer = @import("timer.zig");
pub const errors = @import("errors.zig");

test {
    _ = init;
    _ = video;
    _ = render;
    _ = events;
    _ = rect;
    _ = pixels;
    _ = surface;
    _ = timer;
    _ = errors;
    testing.refAllDecls(@This());
}
