const comp = @import("component.zig");

pub const Robot = struct {
    pub fn init(name: []const u8, pos_x: f32, pos_y: f32) void {
        const entity = comp.ECS_REG.create();
        comp.ECS_REG.add(entity, comp.Robot{ .name = name });
        comp.ECS_REG.add(entity, comp.Position{ .x = pos_x, .y = pos_y });
        comp.ECS_REG.add(entity, comp.Velocity{ .x = 0, .y = 0 });
    }
};
