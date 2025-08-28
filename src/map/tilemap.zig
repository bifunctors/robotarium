const std = @import("std");
const rl = @import("raylib");
const ecs = @import("ecs");
const comp = @import("../component.zig");
const log = @import("log");
const itof = @import("../utils/utils.zig").itof;
const ftou = @import("../utils/utils.zig").ftou;
const ftoi = @import("../utils/utils.zig").ftoi;
const utoi = @import("../utils/utils.zig").utoi;
const Home = @import("../game/home.zig").Home;
const Robot = @import("../game/robot.zig").Robot;
const globals = @import("../globals.zig");
const Tile = @import("tile.zig").Tile;
const BaseType = @import("base_type.zig").BaseType;
const EntityType = @import("entity_type.zig").Entity;

const Arraylist = std.ArrayList;

pub const MAP_WIDTH = 100;
pub const TILE_SIZE = 50;

pub fn generate_map() !Arraylist(Tile) {
    // use actual random stuff like noise functions etc
    const rand = std.crypto.random;
    var list = Arraylist(Tile){};
    for (0..(MAP_WIDTH * MAP_WIDTH)) |_| {
        const num = rand.intRangeAtMost(u8, 0, 5);

        const base: BaseType = switch (num) {
            0 => .ROCK,
            1 => .MUD,
            else => .GRASS,
        };

        const t = Tile{
            .base = base,
        };

        try list.append(std.heap.page_allocator, t);
    }
    return list;
}

pub fn coord_to_idx(x: i32, y: i32) i32 {
    return x + (y * MAP_WIDTH);
}

pub fn get_spawning_square() comp.Position {
    return .{ .x = itof(random_x(MAP_WIDTH / 2) + (MAP_WIDTH / 4)), .y = itof(random_x(MAP_WIDTH / 2) + (MAP_WIDTH / 4)) };
}

pub fn random_square(map: *const Arraylist(BaseType)) i32 {
    const rand = std.crypto.random;
    const num = rand.intRangeAtMost(i32, 0, map.items.len);
    return num;
}

pub fn random_x(len: i32) i32 {
    const rand = std.crypto.random;
    const num = rand.intRangeAtMost(i32, 5, len - 1);
    return num;
}
