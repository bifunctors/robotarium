const std = @import("std");
const rl = @import("raylib");
const ecs = @import("ecs");
const comp = @import("component.zig");
const itof = @import("utils/utils.zig").itof;
const ftou = @import("utils/utils.zig").ftou;
const Home = @import("game/home.zig").Home;
const Robot = @import("game/robot.zig").Robot;

const Arraylist = std.ArrayList;

pub const TILEMAP_WIDTH = 100;
pub const TILE_SIZE = 50;

pub const EntityType = union(enum) {
    HOME: *Home,
    ROBOT: *Robot,
    NONE,

    pub fn to_string(this: *const EntityType) []const u8 {
        return switch(this.*) {
            .HOME => "HOME",
            .ROBOT => "ROBOT",
            .NONE => "NONE",
        };
    }
};

pub const TileType = union(enum) {
    GRASS: u8,
    ROCK,
    MUD,

    pub fn to_string(this: *const TileType) []const u8 {
        return switch(this.*) {
            .GRASS => "GRASS",
            .ROCK => "ROCK",
            .MUD => "MUD",
        };
    }
};

pub var MAP = Arraylist(TileType){};

pub fn generate_map() !Arraylist(TileType) {
    // use actual random stuff like noise functions etc
    const rand = std.crypto.random;
    var list = Arraylist(TileType){};
    for (0..(TILEMAP_WIDTH*TILEMAP_WIDTH)) |_| {
        const num = rand.intRangeAtMost(u8, 0, 5);

        const t: TileType = switch (num) {
            0 => .ROCK,
            1 => .MUD,
            else => TileType{ .GRASS = num },
        };

        try list.append(std.heap.page_allocator, t);
    }
    return list;
}

pub fn coord_to_idx(x: i32, y: i32) i32 {
    return x + (y * TILEMAP_WIDTH);
}

pub fn get_spawning_square() comp.Position {
    return .{ .x = itof(random_x(TILEMAP_WIDTH / 2) + (TILEMAP_WIDTH / 4)), .y = itof(random_x(TILEMAP_WIDTH / 2) + (TILEMAP_WIDTH / 4)) };
}

pub fn check_square(x: i32, y: i32) EntityType {
    var reg = comp.get_registry();
    const square_idx = coord_to_idx(x, y);

    {
        var view = reg.view(.{ Home, comp.Position, comp.Size }, .{});
        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const home = view.get(Home, e);
            const pos = view.get(comp.Position, e);
            const size = view.get(comp.Size, e);

            // Convert floats to integers first
            const start_x: usize = @intFromFloat(pos.x);
            const start_y: usize = @intFromFloat(pos.y);
            const end_x: usize = start_x + @as(usize, @intFromFloat(size.x));
            const end_y: usize = start_y + @as(usize, @intFromFloat(size.y));

            for (start_x..end_x) |i| {
                for (start_y..end_y) |j| {
                    const map_idx = coord_to_idx(@intCast(i), @intCast(j));
                    if (map_idx != square_idx) continue;

                    return EntityType{ .HOME = home };
                }
            }
        }
    }
    {
        var view = reg.view(.{ Robot, comp.Position, comp.Size }, .{});
        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const robot = view.get(Robot, e);
            const pos = robot.get_world_position() orelse continue;
            const size = view.get(comp.Size, e);

            // Convert floats to integers first
            const start_x: usize = @intFromFloat(pos.x);
            const start_y: usize = @intFromFloat(pos.y);
            const end_x: usize = start_x + @as(usize, @intFromFloat(size.x));
            const end_y: usize = start_y + @as(usize, @intFromFloat(size.y));

            for (start_x..end_x) |i| {
                for (start_y..end_y) |j| {
                    const map_idx = coord_to_idx(@intCast(i), @intCast(j));
                    if (map_idx != square_idx) continue;

                    return EntityType{ .ROBOT = robot };
                }
            }
        }
    }
    return .NONE;
}

pub fn random_square(map: *const Arraylist(TileType)) i32 {
    const rand = std.crypto.random;
    const num = rand.intRangeAtMost(i32, 0, map.items.len);
    return num;
}

pub fn random_x(len: i32) i32 {
    const rand = std.crypto.random;
    const num = rand.intRangeAtMost(i32, 5, len - 1);
    return num;
}
