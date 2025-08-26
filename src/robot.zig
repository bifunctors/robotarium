const std = @import("std");
const ecs = @import("ecs");
const comp = @import("component.zig");
const ArrayList = std.ArrayList;

pub const Robot = struct {
    id: ecs.Entity,
    name: []const u8,

    pub fn init(name: []const u8, pos_x: f32, pos_y: f32) ecs.Entity {
        var reg = comp.get_registry();
        const entity = reg.create();
        reg.add(entity, Robot{ .name = name, .id = entity });
        reg.add(entity, comp.Position{ .x = pos_x, .y = pos_y });
        return entity;
    }

    pub fn get_all() ![]*Robot {
        var list = ArrayList(*Robot){};
        var reg = comp.get_registry();

        var view = reg.view(.{ Robot, comp.Position }, .{});

        var iter = view.entityIterator();

        while(iter.next()) |robot| {
            const r = reg.get(Robot, robot);
            try list.append(std.heap.page_allocator, r);
        }

        return list.toOwnedSlice(std.heap.page_allocator);
    }

    pub fn get_name(name: []const u8) ?*Robot {
        var reg = comp.get_registry();
        var view = reg.view(.{ Robot, comp.Position }, .{});
        var iter = view.entityIterator();
        while(iter.next()) |robot| {
            const r = reg.get(Robot, robot);
            if(std.mem.eql(u8, r.name, name)) {
                return r;
            }
        }

        return null;
    }

    pub fn get_position(robot: *Robot) *comp.Position {
        var reg = comp.get_registry();
        const pos = reg.get(comp.Position, robot.id);
        return pos;
    }

    pub fn forward(this: *Robot) void {
        std.debug.print("Moving Robot: {s} forward\n", .{this.name});
    }
};
