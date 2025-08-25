const rl = @import("raylib");
const ecs = @import("ecs");

pub var ECS_REG: ecs.Registry = undefined;

pub const Position = struct { x: f32, y:f32 };
pub const Velocity = struct { x: f32, y:f32 };

pub const Robot = struct {
    name: []const u8,
};
