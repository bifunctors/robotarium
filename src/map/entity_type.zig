const Home = @import("../game/home.zig").Home;
const Robot = @import("../game/robot.zig").Robot;
const tilemap = @import("tilemap.zig");
const comp = @import("../component.zig");
const ftoi = @import("../utils/utils.zig").ftoi;

pub const Entity = union(enum) {
    HOME: *Home,
    ROBOT: *Robot,
    NONE,

    pub fn to_string(this: *const Entity) []const u8 {
        return switch (this.*) {
            .HOME => "HOME",
            .ROBOT => "ROBOT",
            .NONE => "NONE",
        };
    }

    pub fn get_tilef(x: f32, y: f32) Entity {
        return get_tile(ftoi(x), ftoi(y));
    }

    pub fn get_tile(x: i32, y: i32) Entity {
        var reg = comp.get_registry();
        const square_idx = tilemap.coord_to_idx(x, y);

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
                        const map_idx = tilemap.coord_to_idx(@intCast(i), @intCast(j));
                        if (map_idx != square_idx) continue;

                        return Entity{ .HOME = home };
                    }
                }
            }
        }
        {
            var view = reg.view(.{ Robot, comp.Position, comp.Size }, .{});
            var iter = view.entityIterator();
            while (iter.next()) |e| {
                const robot = view.get(Robot, e);
                const pos = robot.get_position() orelse continue;
                const size = view.get(comp.Size, e);

                // Convert floats to integers first
                const start_x: usize = @intFromFloat(pos.x);
                const start_y: usize = @intFromFloat(pos.y);
                const end_x: usize = start_x + @as(usize, @intFromFloat(size.x));
                const end_y: usize = start_y + @as(usize, @intFromFloat(size.y));

                for (start_x..end_x) |i| {
                    for (start_y..end_y) |j| {
                        const map_idx = tilemap.coord_to_idx(@intCast(i), @intCast(j));
                        if (map_idx != square_idx) continue;

                        return Entity{ .ROBOT = robot };
                    }
                }
            }
        }
        return .NONE;
    }
};
