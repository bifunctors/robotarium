const Robot = @import("robot.zig").Robot;
const Inventory = @import("inventory.zig").Inventory;
const InventorySize = @import("inventory.zig").InventorySize;
const comp = @import("../component.zig");

pub const RobotKind = enum {
    scout,

    pub fn to_string(kind: RobotKind) []const u8 {
        return switch(kind) {
            .scout => "Scout"
        };
    }

    pub fn create(kind: RobotKind, name: []const u8, id: usize, home_id: usize) !Robot {
        const movement_tick_speed = switch (kind) {
            .scout => 100,
        };

        const inventory_size: InventorySize = switch(kind) {
            .scout => .small
        };

        const inv = try Inventory.init(inventory_size);

        return Robot{
            .id = id,
            .name = name,
            .home_id = home_id,
            .kind = kind,
            .inventory = inv,
            .cooldown_ticks = movement_tick_speed,
        };
    }

    pub fn get_size(kind: RobotKind) comp.Size {
        return switch(kind) {
            .scout => comp.Size{ .x = 1, .y = 1 },
        };
    }
};
