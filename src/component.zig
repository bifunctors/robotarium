const rl = @import("raylib");
const ecs = @import("ecs");

pub var ECS_REG: ecs.Registry = undefined;

pub const Position = struct { x: f32, y:f32 };
pub const Velocity = struct { x: f32, y:f32 };

pub fn init_registry(reg: ecs.Registry) void {
    ECS_REG = reg;
}

pub fn get_registry() *ecs.Registry {
    return &ECS_REG;
}

