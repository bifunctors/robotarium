const std = @import("std");
const ecs = @import("ecs");
const comp = @import("../component.zig");
const tilemap = @import("../map/tilemap.zig");
const ftoi = @import("../utils/utils.zig").ftoi;
const itof = @import("../utils/utils.zig").itof;
const Player = @import("player.zig").Player;
const ArrayList = std.ArrayList;

pub const Home = struct {
    id: i32,
    player_id: i32,
    range: usize,
    level: usize,

    var next_id: usize = 1;

    pub fn init(player_id: usize) usize {
        var reg = comp.get_registry();
        const entity = reg.create();
        const id = next_id;
        next_id += 1;

        reg.add(entity, Home{
            .id = @intCast(id),
            .player_id = @intCast(player_id),
            .range = 10,
            .level = 1,
        });

        const size = comp.Size{ .x = 2, .y = 2 };
        const spawning_loc = tilemap.get_spawning_square();

        reg.add(entity, spawning_loc);
        reg.add(entity, size);

        return id;
    }

    pub fn from_player_id(player_id: usize) ?*Home {
        var reg = comp.get_registry();
        var view = reg.view(.{Home}, .{});
        var iter = view.entityIterator();
        while (iter.next()) |entity| {
            const home = view.get(Home, entity);
            if (home.player_id != player_id) continue;
            return home;
        }

        return null;
    }

    pub fn get_all() ![]*Home {
        var list = ArrayList(*Home){};
        var reg = comp.get_registry();

        var view = reg.view(.{ Home, comp.Position }, .{});

        var iter = view.entityIterator();

        while (iter.next()) |home| {
            const r = reg.get(Home, home);
            try list.append(std.heap.page_allocator, r);
        }

        return list.toOwnedSlice(std.heap.page_allocator);
    }

    pub fn get_id(id: usize) ?*Home {
        var reg = comp.get_registry();
        var view = reg.view(.{Home}, .{});

        var iter = view.entityIterator();
        while (iter.next()) |e| {
            const home = view.get(e);
            if (home.id != id) continue;
            return home;
        }
        return null;
    }

    pub fn get_position(home: *Home) ?*comp.Position {
        var reg = comp.get_registry();
        var view = reg.view(.{ Home, comp.Position }, .{});
        var iter = view.entityIterator();

        while (iter.next()) |e| {
            const r = reg.get(Home, e);
            if (r.id != home.id) continue;
            return reg.get(comp.Position, e);
        }
        return null;
    }

    pub fn get_size(home: *Home) ?*comp.Size {
        var reg = comp.get_registry();
        var view = reg.view(.{ Home, comp.Size }, .{});
        var iter = view.entityIterator();

        while (iter.next()) |e| {
            const r = reg.get(Home, e);
            if (r.id != home.id) continue;
            return reg.get(comp.Size, e);
        }
        return null;
    }

    pub fn get_player(home: *Home) ?*Player {
        var reg = comp.get_registry();
        var view = reg.view(.{ Player }, .{});
        var iter = view.entityIterator();

        while (iter.next()) |e| {
            const player: *Player = reg.get(Player, e);
            if (player.id != home.player_id) continue;
            return player;
        }
        return null;
    }
};
