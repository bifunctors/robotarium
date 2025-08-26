const std = @import("std");
const rl = @import("raylib");

const Arraylist = std.ArrayList;

pub const TILEMAP_WIDTH = 100;
pub const TILE_SIZE = 50;

pub const TileType = union(enum) {
    grass: u8,
    rock,
    mud,
};

pub fn generate_map() !Arraylist(TileType) {
    // use actual random stuff like noise functions etc
    const rand = std.crypto.random;
    var list = Arraylist(TileType){};
    for (0..10000) |_| {
        const num = rand.intRangeAtMost(u8, 0, 5);

        const t: TileType = switch (num) {
            0 => .rock,
            1 => .mud,
            else => TileType{ .grass = num },
        };

        try list.append(std.heap.page_allocator, t);
    }
    return list;
}

