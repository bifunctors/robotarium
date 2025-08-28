const Item = @import("../game/item.zig").Item;
pub const BaseType = union(enum) {
    grass,
    rock,
    mud,
    coal: Item,

    pub fn to_string(this: *const BaseType) []const u8 {
        return switch (this.*) {
            .grass => "GRASS",
            .rock => "ROCK",
            .mud => "MUD",
            .coal => "CONCRETE",
        };
    }

    pub fn is_mineable(base: *BaseType) bool {
        return switch (base) {
            .coal => true,
            else => false
        };
    }
};
