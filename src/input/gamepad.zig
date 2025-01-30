const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const core = @import("../core/module.zig");
const errors = core.errors;

/// Initialize the gamepad subsystem
pub fn init() !void {
    if (!c.SDL_Init(c.SDL_INIT_GAMEPAD)) {
        return errors.sdlError();
    }
}

/// Shut down the gamepad subsystem
pub fn quit() void {
    c.SDL_QuitSubSystem(c.SDL_INIT_GAMEPAD);
}

pub const Button = enum(c.SDL_GamepadButton) {
    a = c.SDL_GAMEPAD_BUTTON_A,
    b = c.SDL_GAMEPAD_BUTTON_B,
    x = c.SDL_GAMEPAD_BUTTON_X,
    y = c.SDL_GAMEPAD_BUTTON_Y,
    back = c.SDL_GAMEPAD_BUTTON_BACK,
    guide = c.SDL_GAMEPAD_BUTTON_GUIDE,
    start = c.SDL_GAMEPAD_BUTTON_START,
    left_stick = c.SDL_GAMEPAD_BUTTON_LEFT_STICK,
    right_stick = c.SDL_GAMEPAD_BUTTON_RIGHT_STICK,
    left_shoulder = c.SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,
    right_shoulder = c.SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
    dpad_up = c.SDL_GAMEPAD_BUTTON_DPAD_UP,
    dpad_down = c.SDL_GAMEPAD_BUTTON_DPAD_DOWN,
    dpad_left = c.SDL_GAMEPAD_BUTTON_DPAD_LEFT,
    dpad_right = c.SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
    misc1 = c.SDL_GAMEPAD_BUTTON_MISC1,
    paddle1 = c.SDL_GAMEPAD_BUTTON_PADDLE1,
    paddle2 = c.SDL_GAMEPAD_BUTTON_PADDLE2,
    paddle3 = c.SDL_GAMEPAD_BUTTON_PADDLE3,
    paddle4 = c.SDL_GAMEPAD_BUTTON_PADDLE4,
    touchpad = c.SDL_GAMEPAD_BUTTON_TOUCHPAD,
};

pub const Axis = enum(c.SDL_GamepadAxis) {
    left_x = c.SDL_GAMEPAD_AXIS_LEFTX,
    left_y = c.SDL_GAMEPAD_AXIS_LEFTY,
    right_x = c.SDL_GAMEPAD_AXIS_RIGHTX,
    right_y = c.SDL_GAMEPAD_AXIS_RIGHTY,
    left_trigger = c.SDL_GAMEPAD_AXIS_LEFT_TRIGGER,
    right_trigger = c.SDL_GAMEPAD_AXIS_RIGHT_TRIGGER,
};

pub const Type = enum(c.SDL_GamepadType) {
    unknown = c.SDL_GAMEPAD_TYPE_UNKNOWN,
    xbox360 = c.SDL_GAMEPAD_TYPE_XBOX360,
    xboxone = c.SDL_GAMEPAD_TYPE_XBOXONE,
    ps3 = c.SDL_GAMEPAD_TYPE_PS3,
    ps4 = c.SDL_GAMEPAD_TYPE_PS4,
    ps5 = c.SDL_GAMEPAD_TYPE_PS5,
    nintendo_switch_pro = c.SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO,
    virtual_ = c.SDL_GAMEPAD_TYPE_VIRTUAL,
    amazon_luna = c.SDL_GAMEPAD_TYPE_AMAZON_LUNA,
    google_stadia = c.SDL_GAMEPAD_TYPE_GOOGLE_STADIA,
    nvidia_shield = c.SDL_GAMEPAD_TYPE_NVIDIA_SHIELD,
};

pub const Gamepad = struct {
    handle: *c.SDL_Gamepad,

    /// Open a gamepad for use
    pub fn open(joystick_index: i32) !Gamepad {
        const handle = c.SDL_OpenGamepad(joystick_index) orelse {
            return errors.sdlError();
        };
        return Gamepad{ .handle = handle };
    }

    /// Close a gamepad previously opened with open()
    pub fn close(self: *Gamepad) void {
        c.SDL_CloseGamepad(self.handle);
        self.* = undefined;
    }

    /// Get the type of this gamepad
    pub fn getType(self: Gamepad) Type {
        return @enumFromInt(c.SDL_GetGamepadType(self.handle));
    }

    /// Get the current state of a gamepad button
    pub fn getButton(self: Gamepad, button: Button) bool {
        return c.SDL_GetGamepadButton(self.handle, @intFromEnum(button)) == c.SDL_PRESSED;
    }

    /// Get the current state of a gamepad axis
    pub fn getAxis(self: Gamepad, axis: Axis) i16 {
        return c.SDL_GetGamepadAxis(self.handle, @intFromEnum(axis));
    }

    /// Get the current state of a gamepad trigger
    pub fn getTrigger(self: Gamepad, trigger: Axis) f32 {
        std.debug.assert(trigger == .left_trigger or trigger == .right_trigger);
        return c.SDL_GetGamepadAxisInitialState(self.handle, @intFromEnum(trigger));
    }

    /// Start a rumble effect
    pub fn rumble(self: Gamepad, low_frequency: u16, high_frequency: u16, duration_ms: u32) !void {
        if (!c.SDL_RumbleGamepad(self.handle, low_frequency, high_frequency, duration_ms)) {
            return errors.sdlError();
        }
    }

    /// Start a trigger rumble effect
    pub fn rumbleTriggers(self: Gamepad, left: u16, right: u16, duration_ms: u32) !void {
        if (!c.SDL_RumbleGamepadTriggers(self.handle, left, right, duration_ms)) {
            return errors.sdlError();
        }
    }

    /// Query whether a gamepad has an LED
    pub fn hasLED(self: Gamepad) bool {
        return c.SDL_GamepadHasLED(self.handle);
    }

    /// Set the LED color on a gamepad
    pub fn setLED(self: Gamepad, red: u8, green: u8, blue: u8) !void {
        if (!c.SDL_SetGamepadLED(self.handle, red, green, blue)) {
            return errors.sdlError();
        }
    }
};

/// Get the number of attached gamepad devices
pub fn count() i32 {
    return c.SDL_GetGamepadCount();
}

/// Check if the given joystick is supported by the game controller interface
pub fn isGamepad(joystick_index: i32) bool {
    return c.SDL_IsGamepad(joystick_index);
}

/// Get the implementation dependent name for an opened gamepad
pub fn getName(gamepad: Gamepad) ?[*:0]const u8 {
    return c.SDL_GetGamepadName(gamepad.handle);
}

/// Get the implementation dependent path for an opened gamepad
pub fn getPath(gamepad: Gamepad) ?[*:0]const u8 {
    return c.SDL_GetGamepadPath(gamepad.handle);
}

test "gamepad initialization" {
    try init();
    defer quit();
}

test "gamepad enumeration" {
    try init();
    defer quit();

    const num_gamepads = count();
    std.debug.print("Found {} gamepads\n", .{num_gamepads});

    // Note: This test will pass even if no gamepads are connected
    if (num_gamepads > 0) {
        var i: i32 = 0;
        while (i < num_gamepads) : (i += 1) {
            if (isGamepad(i)) {
                var gamepad = try Gamepad.open(i);
                defer gamepad.close();

                const name = getName(gamepad);
                const type_ = gamepad.getType();
                std.debug.print("Gamepad {}: {} (type: {})\n", .{ i, name, type_ });
            }
        }
    }
}

test "gamepad input" {
    try init();
    defer quit();

    if (count() > 0 and isGamepad(0)) {
        var gamepad = try Gamepad.open(0);
        defer gamepad.close();

        // Just test reading values, don't check specific values since they depend on physical input
        _ = gamepad.getButton(.a);
        _ = gamepad.getAxis(.left_x);
        _ = gamepad.getTrigger(.left_trigger);
    }
}
