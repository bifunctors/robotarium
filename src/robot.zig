const std = @import("std");
const ecs = @import("ecs");
const comp = @import("component.zig");
const ArrayList = std.ArrayList;

pub const Robot = struct {
    id: usize,
    name: []const u8,

    var next_robot_id: usize = 1;

    pub fn init(name: []const u8, pos_x: f32, pos_y: f32) !ecs.Entity {
        var reg = comp.get_registry();
        const entity = reg.create();
        const id = next_robot_id;
        next_robot_id += 1;

        const name_copy = try std.heap.page_allocator.alloc(u8, name.len);
        std.mem.copyForwards(u8, name_copy, name);

        reg.add(entity, Robot{
            .name = name_copy,
            .id = id,
        });

        reg.add(entity, comp.Position{ .x = pos_x, .y = pos_y });
        return entity;
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
        var view = reg.view(.{ Robot }, .{});
        var iter = view.entityIterator();

        while(iter.next()) |e| {
            const r = reg.get(Robot, e);
            if(r.id == id) return r;
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

        while(iter.next()) |e| {
            const r = reg.get(Robot, e);
            if(r.id != robot.id) continue;
            return reg.get(comp.Position, e);
        }
        return null;
    }

    pub fn forward(robot: *Robot) void {
        std.debug.print("Moving Robot: {s} forward\n", .{robot.name});
        var pos = robot.get_position() orelse return;
        std.debug.print("Robot Y Before: {}\n", .{pos.y});
        pos.y += 1;
        std.debug.print("Robot Y After: {}\n", .{pos.y});

    }
};
