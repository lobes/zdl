# ZDL - Zig SDL Bindings

Modern Zig bindings for SDL3, with integrated SDL_ttf and SDL_mixer support.

## Features

- Complete SDL3 bindings
- Type-safe wrappers around SDL functionality
- Integrated SDL_ttf support for font rendering
- Integrated SDL_mixer support for audio mixing
- Comprehensive documentation and examples
- Full test coverage

## Requirements

This library requires SDL3 and its extensions to be installed on your system. We require the latest versions:

- [SDL3](https://github.com/libsdl-org/SDL) (version 3.2.0 or later)
- [SDL3_ttf](https://github.com/libsdl-org/SDL_ttf) (version 3.2.0 or later)
- [SDL3_mixer](https://github.com/libsdl-org/SDL_mixer) (version 3.2.0 or later)

### Installing SDL3

#### macOS

```bash
brew install sdl3 sdl3_ttf sdl3_mixer
```

#### Linux

Build from source:

```bash
# SDL3
git clone https://github.com/libsdl-org/SDL.git
cd SDL && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make && sudo make install

# SDL3_ttf
git clone https://github.com/libsdl-org/SDL_ttf.git
cd SDL_ttf && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make && sudo make install

# SDL3_mixer
git clone https://github.com/libsdl-org/SDL_mixer.git
cd SDL_mixer && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make && sudo make install
```

#### Windows

Download and install the development libraries from:

- [SDL3](https://github.com/libsdl-org/SDL/releases)
- [SDL3_ttf](https://github.com/libsdl-org/SDL_ttf/releases)
- [SDL3_mixer](https://github.com/libsdl-org/SDL_mixer/releases)

## Installation

Add to your `build.zig.zon`:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .zdl = .{
            .url = "https://github.com/lobes/zdl/archive/refs/tags/v1.1.7.tar.gz",
            .hash = "12200fc98c62385c07aac654434402148be51895e078189bd9f4cf8dd5a606af45b3",
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

// Add SDL3 system libraries
exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
exe.linkSystemLibrary("SDL3");
exe.linkSystemLibrary("SDL3_ttf");
exe.linkSystemLibrary("SDL3_mixer");
exe.linkLibC();
```

Note: If SDL3 is installed in a different location on your system, you can specify the paths when building:

```bash
zig build -Dsdl-include-path=/path/to/sdl/include -Dsdl-lib-path=/path/to/sdl/lib
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
