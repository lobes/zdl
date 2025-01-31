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
    @import("tests.zig");
}
