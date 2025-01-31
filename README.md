# ZDL - Zig SDL Bindings

Modern Zig bindings for SDL3, with integrated SDL_ttf and SDL_mixer support.

## Features

- Complete SDL3 bindings
- Type-safe wrappers around SDL functionality
- Integrated SDL_ttf support for font rendering
- Integrated SDL_mixer support for audio mixing
- Comprehensive documentation and examples
- Full test coverage

## Installation

Add to your `build.zig.zon`:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .zdl = .{
            .url = "https://github.com/yourusername/zdl/archive/refs/tags/v0.1.0.tar.gz",
            // Update hash after first release
            .hash = "12345...",
        },
    },
}
```

Then in your `build.zig`:

```zig
const zdl = b.dependency("zdl", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("zdl", zdl.module("zdl"));
```

## Usage

```zig
const zdl = @import("zdl");

pub fn main() !void {
    // Initialize SDL
    try zdl.init(.{ .video = true });
    defer zdl.quit();

    // Create window
    var window = try zdl.video.Window.create(
        "My Window",
        800, 600,
        .{ .shown = true },
    );
    defer window.destroy();

    // Create renderer
    var renderer = try zdl.render.Renderer.create(window, .{
        .accelerated = true,
        .vsync = true,
    });
    defer renderer.destroy();

    // Main loop
    mainLoop: while (true) {
        while (zdl.events.pollEvent()) |event| {
            switch (event) {
                .quit => break :mainLoop,
                else => {},
            }
        }

        try renderer.setColor(zdl.pixels.Colors.black);
        try renderer.clear();
        try renderer.present();
    }
}
```

## Documentation

Full documentation is available in the source files and will be hosted online soon.

## License

This project is licensed under the UNLICENCE - see the UNLICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
