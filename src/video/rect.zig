const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");

/// Rectangle with integer coordinates
pub const Rect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    /// Create a new rectangle
    pub fn init(x: i32, y: i32, width: i32, height: i32) Rect {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    /// Convert to SDL_Rect
    pub fn toSDL(self: Rect) c.SDL_Rect {
        return .{
            .x = self.x,
            .y = self.y,
            .w = self.width,
            .h = self.height,
        };
    }

    /// Check if a point is inside the rectangle
    pub fn contains(self: Rect, x: i32, y: i32) bool {
        return x >= self.x and x < self.x + self.width and
            y >= self.y and y < self.y + self.height;
    }

    /// Check if this rectangle intersects with another
    pub fn intersects(self: Rect, other: Rect) bool {
        return self.x < other.x + other.width and
            self.x + self.width > other.x and
            self.y < other.y + other.height and
            self.y + self.height > other.y;
    }

    /// Get the intersection of two rectangles
    pub fn intersection(self: Rect, other: Rect) ?Rect {
        const x = @max(self.x, other.x);
        const y = @max(self.y, other.y);
        const width = @min(self.x + self.width, other.x + other.width) - x;
        const height = @min(self.y + self.height, other.y + other.height) - y;

        if (width <= 0 or height <= 0) return null;

        return Rect.init(x, y, width, height);
    }

    /// Get the union of two rectangles
    pub fn unionRect(self: Rect, other: Rect) Rect {
        const x = @min(self.x, other.x);
        const y = @min(self.y, other.y);
        const width = @max(self.x + self.width, other.x + other.width) - x;
        const height = @max(self.y + self.height, other.y + other.height) - y;

        return Rect.init(x, y, width, height);
    }
};

/// Rectangle with floating point coordinates
pub const FRect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    /// Create a new rectangle
    pub fn init(x: f32, y: f32, width: f32, height: f32) FRect {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    /// Convert to SDL_FRect
    pub fn toSDL(self: FRect) c.SDL_FRect {
        return .{
            .x = self.x,
            .y = self.y,
            .w = self.width,
            .h = self.height,
        };
    }

    /// Check if a point is inside the rectangle
    pub fn contains(self: FRect, x: f32, y: f32) bool {
        return x >= self.x and x < self.x + self.width and
            y >= self.y and y < self.y + self.height;
    }

    /// Check if this rectangle intersects with another
    pub fn intersects(self: FRect, other: FRect) bool {
        return self.x < other.x + other.width and
            self.x + self.width > other.x and
            self.y < other.y + other.height and
            self.y + self.height > other.y;
    }

    /// Get the intersection of two rectangles
    pub fn intersection(self: FRect, other: FRect) ?FRect {
        const x = @max(self.x, other.x);
        const y = @max(self.y, other.y);
        const width = @min(self.x + self.width, other.x + other.width) - x;
        const height = @min(self.y + self.height, other.y + other.height) - y;

        if (width <= 0 or height <= 0) return null;

        return FRect.init(x, y, width, height);
    }

    /// Get the union of two rectangles
    pub fn unionRect(self: FRect, other: FRect) FRect {
        const x = @min(self.x, other.x);
        const y = @min(self.y, other.y);
        const width = @max(self.x + self.width, other.x + other.width) - x;
        const height = @max(self.y + self.height, other.y + other.height) - y;

        return FRect.init(x, y, width, height);
    }
};

test "rectangle operations" {
    // Test integer rectangles
    const rect1 = Rect.init(10, 10, 100, 100);
    const rect2 = Rect.init(50, 50, 100, 100);

    try std.testing.expect(rect1.contains(20, 20));
    try std.testing.expect(!rect1.contains(200, 200));
    try std.testing.expect(rect1.intersects(rect2));

    if (rect1.intersection(rect2)) |intersection| {
        try std.testing.expectEqual(@as(i32, 50), intersection.x);
        try std.testing.expectEqual(@as(i32, 50), intersection.y);
        try std.testing.expectEqual(@as(i32, 60), intersection.width);
        try std.testing.expectEqual(@as(i32, 60), intersection.height);
    } else {
        try std.testing.expect(false);
    }

    const union_rect = rect1.unionRect(rect2);
    try std.testing.expectEqual(@as(i32, 10), union_rect.x);
    try std.testing.expectEqual(@as(i32, 10), union_rect.y);
    try std.testing.expectEqual(@as(i32, 140), union_rect.width);
    try std.testing.expectEqual(@as(i32, 140), union_rect.height);

    // Test floating point rectangles
    const frect1 = FRect.init(10.0, 10.0, 100.0, 100.0);
    const frect2 = FRect.init(50.0, 50.0, 100.0, 100.0);

    try std.testing.expect(frect1.contains(20.0, 20.0));
    try std.testing.expect(!frect1.contains(200.0, 200.0));
    try std.testing.expect(frect1.intersects(frect2));

    if (frect1.intersection(frect2)) |intersection| {
        try std.testing.expectEqual(@as(f32, 50.0), intersection.x);
        try std.testing.expectEqual(@as(f32, 50.0), intersection.y);
        try std.testing.expectEqual(@as(f32, 60.0), intersection.width);
        try std.testing.expectEqual(@as(f32, 60.0), intersection.height);
    } else {
        try std.testing.expect(false);
    }

    const union_frect = frect1.unionRect(frect2);
    try std.testing.expectEqual(@as(f32, 10.0), union_frect.x);
    try std.testing.expectEqual(@as(f32, 10.0), union_frect.y);
    try std.testing.expectEqual(@as(f32, 140.0), union_frect.width);
    try std.testing.expectEqual(@as(f32, 140.0), union_frect.height);
}
