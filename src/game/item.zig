// An Item is any resource that can be put in an inventoyr
// They can have a number attached, which is their *purity* value
// Higher Purity => more rare => more expensive etc
pub const Item = struct {
    kind: ItemKind,
    count: usize,

    pub fn init(kind: ItemKind, count: usize) Item {
        return Item{ .kind = kind, .count = count };
    }
};

pub const ItemKind = union(enum) {
    coal: usize,
    iron: usize,

    pub fn to_string(kind: *const ItemKind) []const u8 {
        return switch (kind.*) {
            .coal => "Coal",
            .iron => "Iron",
        };
    }

    pub fn get_stack_size(kind: ItemKind) usize {
        return switch (kind) {
            .coal => 32,
            .iron => 32,
        };
    }
};
