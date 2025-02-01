# ZDL - Zig SDL3 Bindings

A modern Zig wrapper for SDL3, providing safe and idiomatic bindings while maintaining full access to the underlying C API.

## Features

- Full SDL3 support with optional modules
- Safe Zig bindings with error handling
- Direct access to C API when needed
- Optional modules for TTF, Mixer, etc.
- Modern floating-point rendering coordinates
- Comprehensive examples

## Project Structure

```txt
zdl/
├── zdl.zig           # Main library file
├── build.zig         # Build system
├── build.zig.zon     # Package manifest
├── examples/         # Example programs
│   └── loldongs.zig  # Basic example
└── src/             # Implementation details
    ├── core/        # Core SDL functionality
    ├── video/       # Video and rendering
    ├── audio/       # Audio playback
    └── ...          # Other modules
```

## Installation

Add ZDL as a dependency in your `build.zig.zon`:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .zdl = .{
            .url = "https://github.com/lobes/zdl/archive/<commit-hash>.tar.gz",
        },
    },
}
```

Then in your `build.zig`:

```zig
const zdl_dep = b.dependency("zdl", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("zdl", zdl_dep.module("zdl"));
```

## Usage

Basic example:

```zig
const std = @import("std");
const zdl = @import("zdl");

pub fn main() !void {
    // Initialize SDL with video support
    var app = try zdl.ZDL.init(.{ .video = true });
    defer app.deinit();

    // Create window and renderer
    const window = try zdl.video.Window.create(
        "ZDL Example",
        zdl.c.SDL_WINDOWPOS_CENTERED,
        zdl.c.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        .{ .resizable = true },
    );
    defer window.destroy();

    const renderer = try zdl.video.Renderer.create(window, .{
        .accelerated = true,
        .present_vsync = true,
    });
    defer renderer.destroy();

    // Main loop
    mainLoop: while (true) {
        var event: zdl.c.SDL_Event = undefined;
        while (zdl.c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                zdl.c.SDL_EVENT_QUIT => break :mainLoop,
                else => {},
            }
        }

        try renderer.setColor(0, 0, 0, 255);
        try renderer.clear();
        renderer.present();
    }
}
```

## Building

Requirements:

- Zig 0.13.0 or later
- SDL3 development libraries

Build the library:

```bash
zig build
```

Run tests:

```bash
zig build test
```

Build examples:

```bash
zig build examples
```

## Configuration

The following build options are available:

- `-Dttf=true` - Enable TTF font support
- `-Dmixer=true` - Enable audio mixing support
- `-Dsdl-include-path=/path/to/sdl` - Custom SDL include path
- `-Dsdl-lib-path=/path/to/sdl` - Custom SDL library path

## License

This project is released under the Unlicense. See UNLICENCE for details.
