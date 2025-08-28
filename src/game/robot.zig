const std = @import("std");
const ecs = @import("ecs");
const comp = @import("../component.zig");
const tilemap = @import("../map/tilemap.zig");
const Tile = @import("../map/tile.zig").Tile;
const log = @import("log");
const globals = @import("../globals.zig");
const ftoi = @import("../utils/utils.zig").ftoi;
const itof = @import("../utils/utils.zig").itof;
const utof = @import("../utils/utils.zig").utof;
const Home = @import("home.zig").Home;
const ArrayList = std.ArrayList;

pub const Robot = struct {
    id: usize,
    name: []const u8,
    home_id: usize,
    last_move_tick: u64 = 0,

    var next_robot_id: usize = 1;

    pub fn init(name: []const u8, home_id: usize) !void {
        var reg = comp.get_registry();
        const entity = reg.create();
        const id = next_robot_id;
        next_robot_id += 1;

        const name_copy = try std.heap.page_allocator.alloc(u8, name.len);
        std.mem.copyForwards(u8, name_copy, name);

        const home = Home.get_id(home_id) orelse return;
        const home_pos = home.get_position() orelse return;

        const robot_pos = find_valid_spawn_position(home, home_pos) orelse {
            log.err("Could Not Find a valid position for robot at: {}", .{home.id});
            return;
        };

        const r = Robot{
            .name = name_copy,
            .id = id,
            .home_id = home_id,
        };

        reg.add(entity, r);
        reg.add(entity, comp.Position{ .x = robot_pos.x, .y = robot_pos.y });
        reg.add(entity, comp.Size{ .x = 1, .y = 1 });
    }

    pub fn deinit(robot: *Robot) void {
        std.heap.page_allocator.free(robot.name);
    }

    fn find_valid_spawn_position(_: *Home, home_pos: *comp.Position) ?comp.Position {
        const range = 8;

        // Try random positions
        var attempts: u32 = 0;
        while (attempts < 100) : (attempts += 1) {
            const random = std.crypto.random;
            const offset_x = random.intRangeAtMost(i32, -range, range);
            const offset_y = random.intRangeAtMost(i32, -range, range);

            var test_position = comp.Position{ .x = home_pos.x + @as(f32, @floatFromInt(offset_x)), .y = home_pos.y + @as(f32, @floatFromInt(offset_y)) };

            if (!Tile.has_entity(&test_position)) {
                return test_position;
            }
        }

        // Just search for first one if random doesnt work
        var y: i32 = -range;
        while (y <= range) : (y += 1) {
            var x: i32 = -range;
            while (x <= range) : (x += 1) {
                const test_postion = comp.Position{
                    .x = home_pos.x + @as(f32, @floatFromInt(x)),
                    .y = home_pos.y + @as(f32, @floatFromInt(y)),
                };

                if (!Tile.has_entity(&test_postion)) {
                    return test_postion;
                }
            }
        }

        return null;
    }

    pub fn get_all() ![]*Robot {
        var list = ArrayList(*Robot){};
        var reg = comp.get_registry();

        var view = reg.view(.{ Robot, comp.Position }, .{});

        var iter = view.entityIterator();

        while (iter.next()) |robot| {
            const r = reg.get(Robot, robot);
            try list.append(std.heap.page_allocator, r);
        }

        return list.toOwnedSlice(std.heap.page_allocator);
    }

    pub fn get_id(id: usize) ?*Robot {
        var reg = comp.get_registry();
        var view = reg.view(.{Robot}, .{});
        var iter = view.entityIterator();

        while (iter.next()) |e| {
            const r = reg.get(Robot, e);
            if (r.id == id) return r;
        }
        return null;
    }

    pub fn get_name(name: []const u8) ?*Robot {
        var reg = comp.get_registry();
        var view = reg.view(.{ Robot, comp.Position }, .{});
        var iter = view.entityIterator();
        while (iter.next()) |robot| {
            const r = reg.get(Robot, robot);
            if (std.mem.eql(u8, r.name, name)) {
                return r;
            }
        }

        return null;
    }

    pub fn get_position(robot: *Robot) ?*comp.Position {
        var reg = comp.get_registry();
        var view = reg.view(.{ Robot, comp.Position }, .{});
        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const entity_robot = view.get(Robot, e);
            const pos = view.get(comp.Position, e);
            if (entity_robot.id == robot.id) {
                return pos;
            }
        }
        return null;
    }

    pub fn get_size(robot: *Robot) ?*comp.Size {
        var reg = comp.get_registry();
        var view = reg.view(.{ Robot, comp.Size }, .{});
        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const entity_robot = view.get(Robot, e);
            const size = view.get(comp.Size, e);
            if (entity_robot.id == robot.id) {
                return size;
            }
        }
        return null;
    }

    pub fn get_relative_position(robot: *Robot) ?*comp.Position {
        const robot_pos = robot.get_position() orelse return null;
        const home_pos = robot.get_home().?.get_position() orelse return null;

        var relative_pos = comp.Position{ .x = home_pos.x - robot_pos.x, .y = home_pos.y - robot_pos.y };
        return &relative_pos;
    }

    pub fn get_home(robot: *Robot) ?*Home {
        var reg = comp.get_registry();
        var view = reg.view(.{Home}, .{});
        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const home = view.get(e);
            if (home.id != robot.home_id) continue;
            return home;
        }
        return null;
    }

    pub fn move(robot: *Robot, dir: []const u8) void {
        // Wait 100 ticks before can move again
        if (globals.TICK < robot.last_move_tick + 100) {
            return;
        }

        if (std.mem.eql(u8, dir, "north"))
            if (robot.can_move("north"))
                robot.forward();
        if (std.mem.eql(u8, dir, "south"))
            if (robot.can_move("south"))
                robot.backward();
        if (std.mem.eql(u8, dir, "west"))
            if (robot.can_move("west"))
                robot.left();
        if (std.mem.eql(u8, dir, "east"))
            if (robot.can_move("east"))
                robot.right();

        robot.last_move_tick = globals.TICK;
    }

    pub fn can_move(robot: *Robot, dir: []const u8) bool {
        if (std.mem.eql(u8, dir, "north"))
            return check_movable_tile(robot, 0, -1);
        if (std.mem.eql(u8, dir, "south"))
            return check_movable_tile(robot, 0, 1);
        if (std.mem.eql(u8, dir, "west"))
            return check_movable_tile(robot, -1, 0);
        if (std.mem.eql(u8, dir, "east"))
            return check_movable_tile(robot, 1, 0);

        return false;
    }

    pub fn forward(robot: *Robot) void {
        if (!check_movable_tile(robot, 0, -1)) return;
        robot.get_position().?.y -= 1;
    }

    pub fn backward(robot: *Robot) void {
        if (!check_movable_tile(robot, 0, 1)) return;
        robot.get_position().?.y += 1;
    }

    pub fn left(robot: *Robot) void {
        if (!check_movable_tile(robot, -1, 0)) return;
        robot.get_position().?.x -= 1;
    }

    pub fn right(robot: *Robot) void {
        if (!check_movable_tile(robot, 1, 0)) return;
        robot.get_position().?.x += 1;
    }

    pub fn check_movable_tile(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        if (!check_within_range(robot, x_offset, y_offset)) return false;
        if (!check_tile_not_taken(robot, x_offset, y_offset)) return false;

        return true;
    }

    pub fn check_tile_not_taken(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        const pos = robot.get_position() orelse return false;
        var offset_pos = comp.Position{
            .x = pos.x + x_offset,
            .y = pos.y + y_offset,
        };
        return !Tile.has_entity(&offset_pos);
    }

    pub fn check_within_range(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        const pos = robot.get_position() orelse return false;

        const home = robot.get_home() orelse return false;
        const home_pos = home.get_position() orelse return false;

        const dx = @abs((pos.x + x_offset) - home_pos.x);
        const dy = @abs((pos.y + y_offset) - home_pos.y);

        const range = home.range;

        return dx <= utof(range) and dy <= utof(range);
    }
};
