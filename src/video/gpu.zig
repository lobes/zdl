const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const video = @import("../video/module.zig");
const errors = @import("../core/module.zig");

pub const Device = struct {
    handle: *c.SDL_GPUDevice,

    /// Create a new GPU device with the specified options
    pub fn create(options: DeviceOptions) !Device {
        const handle = c.SDL_CreateGPUDevice(&options.toNative()) orelse {
            return errors.sdlError();
        };
        return Device{ .handle = handle };
    }

    /// Destroy the GPU device and free associated resources
    pub fn destroy(self: *Device) void {
        c.SDL_DestroyGPUDevice(self.handle);
        self.* = undefined;
    }

    /// Claim a window for this GPU device
    pub fn claimWindow(self: *Device, window: *video.Window) !void {
        if (!c.SDL_ClaimWindowForGPUDevice(window.handle, self.handle)) {
            return errors.sdlError();
        }
    }

    /// Get the default command queue for this device
    pub fn getDefaultCommandQueue(self: *Device) !CommandQueue {
        const handle = c.SDL_GetGPUDeviceDefaultCommandQueue(self.handle) orelse {
            return errors.sdlError();
        };
        return CommandQueue{ .handle = handle };
    }
};

pub const DeviceOptions = struct {
    driver_name: ?[*:0]const u8 = null,
    flags: DeviceFlags = .{},

    fn toNative(self: DeviceOptions) c.SDL_GPUDeviceOptions {
        return .{
            .driverName = if (self.driver_name) |name| name else null,
            .flags = self.flags.toNative(),
        };
    }
};

pub const DeviceFlags = packed struct {
    validation: bool = false,
    capture: bool = false,
    _padding: u30 = 0,

    fn toNative(self: DeviceFlags) u32 {
        var flags: u32 = 0;
        if (self.validation) flags |= c.SDL_GPU_DEVICE_VALIDATION;
        if (self.capture) flags |= c.SDL_GPU_DEVICE_CAPTURE;
        return flags;
    }
};

pub const CommandQueue = struct {
    handle: *c.SDL_GPUCommandQueue,

    /// Acquire a command buffer from the queue
    pub fn acquireCommandBuffer(self: *CommandQueue) !CommandBuffer {
        const handle = c.SDL_AcquireGPUCommandBuffer(self.handle) orelse {
            return errors.sdlError();
        };
        return CommandBuffer{ .handle = handle };
    }
};

pub const CommandBuffer = struct {
    handle: *c.SDL_GPUCommandBuffer,

    /// Submit the command buffer for execution
    pub fn submit(self: *CommandBuffer) !void {
        if (!c.SDL_SubmitGPUCommandBuffer(self.handle)) {
            return errors.sdlError();
        }
    }

    /// Wait for the command buffer to complete execution
    pub fn wait(self: *CommandBuffer) !void {
        if (!c.SDL_WaitGPUCommandBuffer(self.handle)) {
            return errors.sdlError();
        }
    }
};

pub const ShaderStage = enum(c.SDL_GPUShaderStage) {
    vertex = c.SDL_GPU_SHADERSTAGE_VERTEX,
    fragment = c.SDL_GPU_SHADERSTAGE_FRAGMENT,
};

pub const ShaderFormat = enum(u32) {
    invalid = c.SDL_GPU_SHADERFORMAT_INVALID,
    private = c.SDL_GPU_SHADERFORMAT_PRIVATE,
    spirv = c.SDL_GPU_SHADERFORMAT_SPIRV,
    dxbc = c.SDL_GPU_SHADERFORMAT_DXBC,
    dxil = c.SDL_GPU_SHADERFORMAT_DXIL,
    msl = c.SDL_GPU_SHADERFORMAT_MSL,
    metallib = c.SDL_GPU_SHADERFORMAT_METALLIB,
};

pub const Shader = struct {
    handle: *c.SDL_GPUShader,

    /// Create a new shader with the specified code and configuration
    pub fn create(device: *Device, info: ShaderCreateInfo) !Shader {
        const native_info = info.toNative();
        const handle = c.SDL_CreateGPUShader(device.handle, &native_info) orelse {
            return errors.sdlError();
        };
        return Shader{ .handle = handle };
    }

    /// Release the shader and free associated resources
    pub fn release(self: *Shader) void {
        c.SDL_ReleaseGPUShader(self.handle);
        self.* = undefined;
    }
};

pub const ShaderCreateInfo = struct {
    code: []const u8,
    entrypoint: [*:0]const u8,
    format: ShaderFormat,
    stage: ShaderStage,
    num_samplers: u32 = 0,
    num_storage_textures: u32 = 0,
    num_storage_buffers: u32 = 0,
    num_uniform_buffers: u32 = 0,
    props: c.SDL_PropertiesID = 0,

    fn toNative(self: ShaderCreateInfo) c.SDL_GPUShaderCreateInfo {
        return .{
            .code_size = self.code.len,
            .code = self.code.ptr,
            .entrypoint = self.entrypoint,
            .format = @intFromEnum(self.format),
            .stage = @intFromEnum(self.stage),
            .num_samplers = self.num_samplers,
            .num_storage_textures = self.num_storage_textures,
            .num_storage_buffers = self.num_storage_buffers,
            .num_uniform_buffers = self.num_uniform_buffers,
            .props = self.props,
        };
    }
};

pub const BufferUsage = packed struct {
    vertex: bool = false,
    index: bool = false,
    uniform: bool = false,
    graphics_storage_read: bool = false,
    graphics_storage_write: bool = false,
    compute_storage_read: bool = false,
    compute_storage_write: bool = false,
    _padding: u25 = 0,

    fn toNative(self: BufferUsage) u32 {
        var flags: u32 = 0;
        if (self.vertex) flags |= c.SDL_GPU_BUFFERUSAGE_VERTEX;
        if (self.index) flags |= c.SDL_GPU_BUFFERUSAGE_INDEX;
        if (self.uniform) flags |= c.SDL_GPU_BUFFERUSAGE_UNIFORM;
        if (self.graphics_storage_read) flags |= c.SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ;
        if (self.graphics_storage_write) flags |= c.SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_WRITE;
        if (self.compute_storage_read) flags |= c.SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ;
        if (self.compute_storage_write) flags |= c.SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE;
        return flags;
    }
};

pub const Buffer = struct {
    handle: *c.SDL_GPUBuffer,

    /// Create a new GPU buffer with the specified size and usage flags
    pub fn create(device: *Device, size: usize, usage: BufferUsage) !Buffer {
        const handle = c.SDL_CreateGPUBuffer(device.handle, size, usage.toNative()) orelse {
            return errors.sdlError();
        };
        return Buffer{ .handle = handle };
    }

    /// Upload data to the buffer
    pub fn upload(self: *Buffer, data: []const u8) !void {
        if (!c.SDL_UploadToGPUBuffer(self.handle, data.ptr, data.len)) {
            return errors.sdlError();
        }
    }

    /// Release the buffer and free associated resources
    pub fn release(self: *Buffer) void {
        c.SDL_ReleaseGPUBuffer(self.handle);
        self.* = undefined;
    }
};

pub const TextureType = enum(c.SDL_GPUTextureType) {
    tex1d = c.SDL_GPU_TEXTURETYPE_1D,
    tex2d = c.SDL_GPU_TEXTURETYPE_2D,
    tex3d = c.SDL_GPU_TEXTURETYPE_3D,
    tex1d_array = c.SDL_GPU_TEXTURETYPE_1D_ARRAY,
    tex2d_array = c.SDL_GPU_TEXTURETYPE_2D_ARRAY,
    cube = c.SDL_GPU_TEXTURETYPE_CUBE,
    cube_array = c.SDL_GPU_TEXTURETYPE_CUBE_ARRAY,
};

pub const TextureFormat = enum(c.SDL_GPUTextureFormat) {
    r8_unorm = c.SDL_GPU_TEXTUREFORMAT_R8_UNORM,
    r8g8_unorm = c.SDL_GPU_TEXTUREFORMAT_R8G8_UNORM,
    r8g8b8a8_unorm = c.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
    r8g8b8a8_srgb = c.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SRGB,
    b8g8r8a8_unorm = c.SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM,
    b8g8r8a8_srgb = c.SDL_GPU_TEXTUREFORMAT_B8G8R8A8_SRGB,
    r32_float = c.SDL_GPU_TEXTUREFORMAT_R32_FLOAT,
    r32g32_float = c.SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT,
    r32g32b32a32_float = c.SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT,
    d32_float = c.SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
    d24_unorm_s8_uint = c.SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT,
};

pub const TextureUsage = packed struct {
    sampler: bool = false,
    color_target: bool = false,
    depth_stencil_target: bool = false,
    graphics_storage_read: bool = false,
    graphics_storage_write: bool = false,
    compute_storage_read: bool = false,
    compute_storage_write: bool = false,
    _padding: u25 = 0,

    fn toNative(self: TextureUsage) u32 {
        var flags: u32 = 0;
        if (self.sampler) flags |= c.SDL_GPU_TEXTUREUSAGE_SAMPLER;
        if (self.color_target) flags |= c.SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
        if (self.depth_stencil_target) flags |= c.SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET;
        if (self.graphics_storage_read) flags |= c.SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ;
        if (self.graphics_storage_write) flags |= c.SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_WRITE;
        if (self.compute_storage_read) flags |= c.SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ;
        if (self.compute_storage_write) flags |= c.SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE;
        return flags;
    }
};

pub const SampleCount = enum(c.SDL_GPUSampleCount) {
    @"1" = c.SDL_GPU_SAMPLECOUNT_1,
    @"2" = c.SDL_GPU_SAMPLECOUNT_2,
    @"4" = c.SDL_GPU_SAMPLECOUNT_4,
    @"8" = c.SDL_GPU_SAMPLECOUNT_8,
    @"16" = c.SDL_GPU_SAMPLECOUNT_16,
};

pub const Texture = struct {
    handle: *c.SDL_GPUTexture,

    /// Create a new texture with the specified configuration
    pub fn create(device: *Device, info: TextureCreateInfo) !Texture {
        const native_info = info.toNative();
        const handle = c.SDL_CreateGPUTexture(device.handle, &native_info) orelse {
            return errors.sdlError();
        };
        return Texture{ .handle = handle };
    }

    /// Upload data to the texture
    pub fn upload(self: *Texture, data: []const u8, row_pitch: usize, depth_pitch: usize) !void {
        if (!c.SDL_UploadToGPUTexture(self.handle, data.ptr, row_pitch, depth_pitch)) {
            return errors.sdlError();
        }
    }

    /// Release the texture and free associated resources
    pub fn release(self: *Texture) void {
        c.SDL_ReleaseGPUTexture(self.handle);
        self.* = undefined;
    }
};

pub const TextureCreateInfo = struct {
    type: TextureType,
    format: TextureFormat,
    usage: TextureUsage,
    width: u32,
    height: u32,
    layer_count_or_depth: u32 = 1,
    num_levels: u32 = 1,
    sample_count: SampleCount = .@"1",
    props: c.SDL_PropertiesID = 0,

    fn toNative(self: TextureCreateInfo) c.SDL_GPUTextureCreateInfo {
        return .{
            .type = @intFromEnum(self.type),
            .format = @intFromEnum(self.format),
            .usage = self.usage.toNative(),
            .width = self.width,
            .height = self.height,
            .layer_count_or_depth = self.layer_count_or_depth,
            .num_levels = self.num_levels,
            .sample_count = @intFromEnum(self.sample_count),
            .props = self.props,
        };
    }
};

pub const SamplerAddressMode = enum(c.SDL_GPUSamplerAddressMode) {
    repeat = c.SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
    mirrored_repeat = c.SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT,
    clamp_to_edge = c.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
    clamp_to_border = c.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_BORDER,
};

pub const SamplerFilter = enum(c.SDL_GPUSamplerFilter) {
    nearest = c.SDL_GPU_SAMPLERFILTER_NEAREST,
    linear = c.SDL_GPU_SAMPLERFILTER_LINEAR,
};

pub const SamplerMipmapMode = enum(c.SDL_GPUSamplerMipmapMode) {
    none = c.SDL_GPU_SAMPLERMIPMAP_NONE,
    nearest = c.SDL_GPU_SAMPLERMIPMAP_NEAREST,
    linear = c.SDL_GPU_SAMPLERMIPMAP_LINEAR,
};

pub const Sampler = struct {
    handle: *c.SDL_GPUSampler,

    /// Create a new sampler with the specified configuration
    pub fn create(device: *Device, info: SamplerCreateInfo) !Sampler {
        const native_info = info.toNative();
        const handle = c.SDL_CreateGPUSampler(device.handle, &native_info) orelse {
            return errors.sdlError();
        };
        return Sampler{ .handle = handle };
    }

    /// Release the sampler and free associated resources
    pub fn release(self: *Sampler) void {
        c.SDL_ReleaseGPUSampler(self.handle);
        self.* = undefined;
    }
};

pub const SamplerCreateInfo = struct {
    address_mode_u: SamplerAddressMode = .clamp_to_edge,
    address_mode_v: SamplerAddressMode = .clamp_to_edge,
    address_mode_w: SamplerAddressMode = .clamp_to_edge,
    min_filter: SamplerFilter = .nearest,
    mag_filter: SamplerFilter = .nearest,
    mipmap_mode: SamplerMipmapMode = .none,
    min_lod: f32 = 0,
    max_lod: f32 = 1000,
    props: c.SDL_PropertiesID = 0,

    fn toNative(self: SamplerCreateInfo) c.SDL_GPUSamplerCreateInfo {
        return .{
            .addressMode_u = @intFromEnum(self.address_mode_u),
            .addressMode_v = @intFromEnum(self.address_mode_v),
            .addressMode_w = @intFromEnum(self.address_mode_w),
            .minFilter = @intFromEnum(self.min_filter),
            .magFilter = @intFromEnum(self.mag_filter),
            .mipmapMode = @intFromEnum(self.mipmap_mode),
            .minLOD = self.min_lod,
            .maxLOD = self.max_lod,
            .props = self.props,
        };
    }
};

test "gpu device creation and destruction" {
    const device = try Device.create(.{});
    defer device.destroy();
}

test "gpu command queue and buffer" {
    const device = try Device.create(.{});
    defer device.destroy();

    var queue = try device.getDefaultCommandQueue();
    var cmd_buffer = try queue.acquireCommandBuffer();
    try cmd_buffer.submit();
    try cmd_buffer.wait();
}

test "shader creation and release" {
    const device = try Device.create(.{});
    defer device.destroy();

    const shader_code = @embedFile("shaders/test.spv");
    var shader = try Shader.create(device, .{
        .code = shader_code,
        .entrypoint = "main",
        .format = .spirv,
        .stage = .vertex,
    });
    defer shader.release();
}

test "buffer creation and upload" {
    const device = try Device.create(.{});
    defer device.destroy();

    const vertices = [_]f32{ 0.0, 0.5, 1.0, -0.5, -0.5, 1.0, 0.5, -0.5, 1.0 };
    var buffer = try Buffer.create(device, @sizeOf(@TypeOf(vertices)), .{ .vertex = true });
    defer buffer.release();

    try buffer.upload(std.mem.sliceAsBytes(&vertices));
}

test "texture creation and upload" {
    const device = try Device.create(.{});
    defer device.destroy();

    const pixels = [_]u8{ 255, 0, 0, 255 }; // Red pixel
    var texture = try Texture.create(device, .{
        .type = .tex2d,
        .format = .r8g8b8a8_unorm,
        .usage = .{ .sampler = true },
        .width = 1,
        .height = 1,
    });
    defer texture.release();

    try texture.upload(&pixels, 4, 4);
}

test "sampler creation" {
    const device = try Device.create(.{});
    defer device.destroy();

    var sampler = try Sampler.create(device, .{
        .min_filter = .linear,
        .mag_filter = .linear,
        .mipmap_mode = .linear,
    });
    defer sampler.release();
}
