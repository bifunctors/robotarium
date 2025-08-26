const std = @import("std");
const tilemap = @import("tilemap.zig");
const Robot = @import("robot.zig").Robot;
const Home = @import("game/home.zig").Home;
const ftoi = @import("utils.zig").ftoi;
const rl = @import("raylib");

const Arraylist = std.ArrayList;
const TileType = tilemap.TileType;
const TILEMAP_WIDTH = tilemap.TILEMAP_WIDTH;
const TILE_SIZE = tilemap.TILE_SIZE;

pub fn render(map: *const Arraylist(TileType)) void {
    render_tilemap(map);
    render_homes();
    render_robots();
}

fn render_robots() void {
    const robots = Robot.get_all() catch return;

    for (robots) |robot| {
        const pos = robot.get_world_position() orelse continue;
        rl.drawRectangle(toi(pos.x) * TILE_SIZE, toi(pos.y) * TILE_SIZE, 50, 50, .orange);
    }
}

fn render_homes() void {
    const homes = Home.get_all() catch return;

    for (homes) |home| {
        const pos = home.get_position() orelse continue;
        const size = home.get_size() orelse continue;

        rl.drawRectangle(
            toi(pos.x) * TILE_SIZE,
            toi(pos.y) * TILE_SIZE,
            TILE_SIZE * ftoi(size.x),
            TILE_SIZE * ftoi(size.y),
            .purple,
        );
    }
}

pub fn render_tilemap(map: *const Arraylist(TileType)) void {
    const cols: i32 = TILEMAP_WIDTH;
    const rows: i32 = @intCast(map.items.len / TILEMAP_WIDTH);

    for (map.items, 0..) |tile, idx| {
        const x: i32 = @intCast((idx % TILEMAP_WIDTH) * TILE_SIZE);
        const y: i32 = @intCast((idx / TILEMAP_WIDTH) * TILE_SIZE);

        switch (tile) {
            .MUD => rl.drawRectangle(x, y, TILE_SIZE, TILE_SIZE, .dark_brown),
            .ROCK => rl.drawRectangle(x, y, TILE_SIZE, TILE_SIZE, .dark_gray),
            .GRASS => rl.drawRectangle(x, y, TILE_SIZE, TILE_SIZE, .dark_green),
        }
    }

    for (0..cols + 1) |c| {
        const x: i32 = @as(i32, @intCast(c)) * TILE_SIZE;
        rl.drawLine(x, 0, x, rows * TILE_SIZE, rl.Color.black);
    }

    for (0..@as(usize, @intCast(rows + 1))) |r| {
        const y: i32 = @as(i32, @intCast(r)) * TILE_SIZE;
        rl.drawLine(0, y, cols * TILE_SIZE, y, rl.Color.black);
    }
}

fn toi(x: anytype) i32 {
    return @as(i32, @intFromFloat(x));
}
