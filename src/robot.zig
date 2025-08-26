const std = @import("std");
const ecs = @import("ecs");
const comp = @import("component.zig");
const tilemap = @import("tilemap.zig");
const ftoi = @import("utils.zig").ftoi;
const Home = @import("game/home.zig").Home;
const ArrayList = std.ArrayList;

pub const Robot = struct {
    id: usize,
    name: []const u8,
    home_id: usize,
    // This is the position relative to "Home"
    relative_position: comp.Position,

    var next_robot_id: usize = 1;

    pub fn init(name: []const u8, home_id: usize) !void {
        var reg = comp.get_registry();
        const entity = reg.create();
        const id = next_robot_id;
        next_robot_id += 1;

        const name_copy = try std.heap.page_allocator.alloc(u8, name.len);
        std.mem.copyForwards(u8, name_copy, name);

        const relative_position = comp.Position{ .x = 0, .y = 1 };

        reg.add(entity, Robot{
            .name = name_copy,
            .id = id,
            .relative_position = relative_position,
            .home_id = home_id,
        });

        const home = Home.get_id(home_id) orelse return;
        const pos = home.get_position() orelse return;
        std.debug.print("Home Position Is: {}\n", .{pos});
        const size = home.get_size() orelse return;

        const x = pos.x;
        const y = pos.y + (size.y) - 1;

        const square_data = tilemap.check_square(
            ftoi(x + relative_position.x),
            ftoi(y + relative_position.y),
        );

        std.debug.print("At Square:{},{}, there is {}\n", .{
            x + relative_position.x,
            y + relative_position.y,
            square_data,
        });

        reg.add(entity, comp.Position{ .x = x, .y = y });
        reg.add(entity, comp.Size{ .x = 1, .y = 1 });
    }

    pub fn deinit(robot: *Robot) void {
        std.heap.page_allocator.free(robot.name);
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
        return &robot.relative_position;
    }

    pub fn get_world_position(robot: *Robot) ?comp.Position {
        var reg = comp.get_registry();
        var view = reg.view(.{ Robot, comp.Position }, .{});
        var iter = view.entityIterator();

        while (iter.next()) |e| {
            const r = reg.get(Robot, e);
            if (r.id != robot.id) continue;
            const pos = reg.get(comp.Position, e);
            return comp.Position{
                .x = pos.x + robot.relative_position.x,
                .y = pos.y + robot.relative_position.y,
            };
        }
        return null;
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
        if (std.mem.eql(u8, dir, "north"))
            robot.forward();
        if (std.mem.eql(u8, dir, "south"))
            robot.backward();
        if (std.mem.eql(u8, dir, "west"))
            robot.left();
        if (std.mem.eql(u8, dir, "east"))
            robot.right();
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
        if(!check_movable_tile(robot, 0, -1)) return;
        robot.relative_position.y -= 1;
    }

    pub fn backward(robot: *Robot) void {
        if(!check_movable_tile(robot, 0, 1)) return;
        robot.relative_position.y += 1;
    }

    pub fn left(robot: *Robot) void {
        if(!check_movable_tile(robot, -1, 0)) return;
        robot.relative_position.x -= 1;
    }

    pub fn right(robot: *Robot) void {
        if(!check_movable_tile(robot, 1, 0)) return;
        robot.relative_position.x += 1;
    }

    pub fn check_movable_tile(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        if(!check_within_range(robot, x_offset, y_offset)) return false;
        if(!check_tile_not_taken(robot, x_offset, y_offset)) return false;

        return true;
    }

    pub fn check_tile_not_taken(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        const pos = robot.get_world_position() orelse return false;
        const square = tilemap.check_square(ftoi(pos.x + x_offset), ftoi(pos.y + y_offset));
        return square == .NONE;
    }

    const HOME_RANGE = 10;

    pub fn check_within_range(robot: *Robot, x_offset: f32, y_offset: f32) bool {
        const pos = robot.get_world_position() orelse return false;

        const home = robot.get_home() orelse return false;
        const home_pos = home.get_position() orelse return false;

        const dx = @abs((pos.x + x_offset) - home_pos.x);
        const dy = @abs((pos.y + y_offset) - home_pos.y);

        return dx <= HOME_RANGE and dy <= HOME_RANGE;
    }
};
