const std = @import("std");
const ecs = @import("ecs");
const comp = @import("../component.zig");
const Home = @import("home.zig").Home;
const ArrayList = std.ArrayList;

pub const Player = struct {
    id: i32,
    name: []const u8,

    var next_player_id: usize = 1;

    pub fn init(name: []const u8) !usize {
        // Create Home
        var reg = comp.get_registry();
        const entity = reg.create();
        const id = next_player_id;
        next_player_id += 1;

        const name_copy = try std.heap.page_allocator.alloc(u8, name.len);
        std.mem.copyForwards(u8, name_copy, name);

        reg.add(entity, Player{
            .id = @intCast(id),
            .name = name_copy,
        });

        return Home.init(id);
    }
};
