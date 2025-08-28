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
};
