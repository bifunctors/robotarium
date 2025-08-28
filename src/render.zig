const std = @import("std");
const tilemap = @import("tilemap.zig");
const Robot = @import("game/robot.zig").Robot;
const Home = @import("game/home.zig").Home;
const ftoi = @import("utils/utils.zig").ftoi;
const itof = @import("utils/utils.zig").itof;
const ftou = @import("utils/utils.zig").ftou;
const utof = @import("utils/utils.zig").utof;
const utoi = @import("utils/utils.zig").utoi;
const comp = @import("component.zig");
const rl = @import("raylib");
const main = @import("main.zig");
const Notification = @import("ui/notification.zig").Notification;
const NotificationRenderer = @import("ui/notification.zig").NotificationRenderer;

const Arraylist = std.ArrayList;
const TileType = tilemap.TileType;
const TILEMAP_WIDTH = tilemap.TILEMAP_WIDTH;
const TILE_SIZE = tilemap.TILE_SIZE;

pub fn render(map: *const Arraylist(TileType), camera: *rl.Camera2D) void {
    render_tilemap(map);
    render_homes();
    render_robots();
    render_mouse(map, camera);
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

fn render_mouse(map: *const Arraylist(TileType), camera: *rl.Camera2D) void {
    const mouse_pos = rl.getMousePosition();
    const world_mouse_pos = rl.getScreenToWorld2D(mouse_pos, camera.*);

    const tile_x = ftoi(world_mouse_pos.x / TILE_SIZE);
    const tile_y = ftoi(world_mouse_pos.y / TILE_SIZE);

    const cols: i32 = TILEMAP_WIDTH;
    const rows: i32 = @intCast(map.items.len / TILEMAP_WIDTH);

    if (tile_x >= 0 and tile_x < cols and tile_y >= 0 and tile_y < rows) {
        const highlight_x = tile_x * TILE_SIZE;
        const highlight_y = tile_y * TILE_SIZE;

        rl.drawRectangle(highlight_x, highlight_y, TILE_SIZE, TILE_SIZE, rl.Color{ .r = 255, .g = 255, .b = 0, .a = 100 } // Semi-transparent yellow
        );

        rl.drawRectangleLines(highlight_x, highlight_y, TILE_SIZE, TILE_SIZE, rl.Color.yellow);
    }
}

pub fn get_mouse_tile(camera: *rl.Camera2D) comp.Position {
    const mouse_pos = rl.getMousePosition();
    const world_mouse_pos = rl.getScreenToWorld2D(mouse_pos, camera.*);

    const tile_x = ftoi(world_mouse_pos.x / TILE_SIZE);
    const tile_y = ftoi(world_mouse_pos.y / TILE_SIZE);
    return .{ .x = itof(tile_x), .y = itof(tile_y) };
}

pub fn get_mouse_tile_type(map: *const Arraylist(TileType), camera: *rl.Camera2D) ?TileType {
    const mouse_pos = rl.getMousePosition();
    const world_mouse_pos = rl.getScreenToWorld2D(mouse_pos, camera.*);

    const tile_x = ftoi(world_mouse_pos.x / TILE_SIZE);
    const tile_y = ftoi(world_mouse_pos.y / TILE_SIZE);

    const cols: i32 = TILEMAP_WIDTH;
    const rows: i32 = @intCast(map.items.len / TILEMAP_WIDTH);

    if (tile_x >= 0 and tile_x < cols and tile_y >= 0 and tile_y < rows) {
        // Calculate the index in the map array
        const tile_index = @as(usize, @intCast(tile_y * cols + tile_x));

        // Return the tile type at this position
        return map.items[tile_index];
    }

    // Return null if mouse is outside the tilemap bounds
    return null;
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

pub fn render_notifications(dt: f32) void {
    var i: usize = 0;
    while (i < Notification.Notifications.items.len) {
        const notif = &Notification.Notifications.items[i];

        if (notif.timer >= notif.duration) {
            _ = Notification.Notifications.orderedRemove(i);
            break;
        }

        notif.timer += dt;
        const progress = notif.timer / notif.duration;

        // Format message once
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, "{s}", .{notif.msg}) catch "Error";

        // Calculate dimensions
        const text_width = rl.measureText(msg, NotificationRenderer.FONT_SIZE);
        const actual_width = @max(text_width + (NotificationRenderer.NOTIF_PADDING * 2), NotificationRenderer.NOTIF_WIDTH);

        // Position with animation
        const base_y = NotificationRenderer.NOTIF_MARGIN +
            (NotificationRenderer.NOTIF_HEIGHT + NotificationRenderer.NOTIF_MARGIN) * @as(i32, @intCast(i));
        const offset_x = NotificationRenderer.calculateOffset(progress);

        const rect = rl.Rectangle{
            .x = @as(f32, @floatFromInt(main.WIDTH)) - @as(f32, @floatFromInt(actual_width)) -
                @as(f32, @floatFromInt(NotificationRenderer.NOTIF_MARGIN)) + offset_x,
            .y = @as(f32, @floatFromInt(base_y)),
            .width = @as(f32, @floatFromInt(actual_width)),
            .height = @as(f32, @floatFromInt(NotificationRenderer.NOTIF_HEIGHT)),
        };

        // Calculate colors with fade
        const alpha = NotificationRenderer.calculateAlpha(progress);
        const bg_color = rl.Color{ .r = 255, .g = 182, .b = 193, .a = @as(u8, @intFromFloat(alpha * 200)) }; // Pink with alpha
        const border_color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = @as(u8, @intFromFloat(alpha * 255)) };
        const text_color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = @as(u8, @intFromFloat(alpha * 255)) };

        // Render notification
        rl.drawRectangleRounded(rect, NotificationRenderer.CORNER_RADIUS, NotificationRenderer.CORNER_SEGMENTS, bg_color);
        rl.drawRectangleRoundedLinesEx(rect, NotificationRenderer.CORNER_RADIUS, NotificationRenderer.CORNER_SEGMENTS, 2, border_color);

        // Center text vertically
        const text_y = @as(i32, @intFromFloat(rect.y)) +
            (NotificationRenderer.NOTIF_HEIGHT - NotificationRenderer.FONT_SIZE) / 2;
        const text_x = @as(i32, @intFromFloat(rect.x)) + NotificationRenderer.NOTIF_PADDING;

        rl.drawText(msg, text_x, text_y, NotificationRenderer.FONT_SIZE, text_color);

        i += 1;
    }
}

fn toi(x: anytype) i32 {
    return @as(i32, @intFromFloat(x));
}
