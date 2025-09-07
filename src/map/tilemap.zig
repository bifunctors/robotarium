const std = @import("std");
const rl = @import("raylib");
const ecs = @import("ecs");
const comp = @import("../component.zig");
const log = @import("log");
const kf = @import("kfolders");
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

pub const MAP_WIDTH = 500;
pub const TILE_SIZE = 50;

pub fn generate_map() !Arraylist(Tile) {
    // use actual random stuff like noise functions etc
    const rand = std.crypto.random;
    var list = Arraylist(Tile){};
    for (0..(MAP_WIDTH * MAP_WIDTH)) |_| {
        const num = rand.intRangeAtMost(u8, 0, 5);

        const base: BaseType = switch (num) {
            0 => .rock,
            1 => .mud,
            else => .grass,
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

pub fn save_map() !void {
    const map = globals.MAP;

    const config_folder = try kf.getPath(std.heap.page_allocator, .local_configuration);

    if (config_folder) |folder| {
        const config_path = try std.fs.path.join(
            std.heap.page_allocator,
            &[_][]const u8{ folder, "scan_game" },
        );
        const map_save_path = try std.fs.path.join(
            std.heap.page_allocator,
            &[_][]const u8{ config_path, "map.bak" },
        );

        defer std.heap.page_allocator.free(config_path);
        defer std.heap.page_allocator.free(map_save_path);
        var buf: [200]u8 = undefined;
        const path_formatted = std.fmt.bufPrintZ(&buf, "{s}", .{map_save_path}) catch "";

        std.fs.makeDirAbsolute(config_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const map_json = std.json.fmt(map, .{ .whitespace = .indent_2 });
        var writer = std.io.Writer.Allocating.init(std.heap.page_allocator);
        try map_json.format(&writer.writer);
        const str = try writer.toOwnedSlice();

        log.debug("Writing Save File", .{});

        const save_file = try std.fs.createFileAbsolute(path_formatted, .{});
        _ = try save_file.write(str);
        save_file.close();

    } else {
        log.err("Could Not Save Map To File", .{});
        log.err("Could Not Open XDG_CONFIG Directory", .{});
    }
}
