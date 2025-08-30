const std = @import("std");
const tilemap = @import("map/tilemap.zig");
const Robot = @import("game/robot.zig").Robot;
const Home = @import("game/home.zig").Home;
const Tile = @import("map/tile.zig").Tile;
const ftoi = @import("utils/utils.zig").ftoi;
const itof = @import("utils/utils.zig").itof;
const ftou = @import("utils/utils.zig").ftou;
const utof = @import("utils/utils.zig").utof;
const utoi = @import("utils/utils.zig").utoi;
const log = @import("log");
const comp = @import("component.zig");
const rl = @import("raylib");
const globals = @import("globals.zig");
const main = @import("main.zig");
const Chunk = @import("map/chunk.zig").Chunk;
const ChunkManager = @import("map/chunk.zig").ChunkManager;
const CHUNK_SIZE = @import("map/chunk.zig").CHUNK_SIZE;
const Notification = @import("ui/notification.zig").Notification;
const NotificationRenderer = @import("ui/notification.zig").NotificationRenderer;

const Arraylist = std.ArrayList;
const TileType = tilemap.BaseType;
const TILEMAP_WIDTH = tilemap.MAP_WIDTH;
const TILE_SIZE = tilemap.TILE_SIZE;

pub fn render(camera: *rl.Camera2D, chunk_manager: *ChunkManager) void {
    render_tilemap(camera, chunk_manager);
    render_robots();
    render_homes();
    render_mouse(camera);
}

fn render_robots() void {
    const robots = Robot.get_all() catch return;
    const padding = 10;

    for (robots) |robot| {
        const pos = robot.get_position() orelse continue;
        const size = robot.get_size() orelse continue;

        const ticks_since_move = globals.TICK - robot.last_move_tick;
        const cooldown_progress = @min(@as(f32, @floatFromInt(ticks_since_move)) / @as(f32, @floatFromInt(robot.cooldown_ticks)), 1.0);

        // Interpolate from red (255,0,0) to orange (255,165,0)
        const red: u8 = 255; // Always full red
        const green: u8 = @as(u8, @intFromFloat(cooldown_progress * 165.0)); // 0 -> 165
        const blue: u8 = 0; // Always 0

        const colour = rl.Color{
            .r = red,
            .g = green,
            .b = blue,
            .a = 255,
        };

        const tile_x = ord_to_tile(pos.x);
        const tile_y = ord_to_tile(pos.y);
        rl.drawRectangle(
            tile_x + (padding / 2),
            tile_y + (padding / 2),
            (TILE_SIZE * ftoi(size.x)) - padding,
            (TILE_SIZE * ftoi(size.y)) - padding,
            colour,
        );

        // Format name
        var buf: [100]u8 = undefined;
        const name = std.fmt.bufPrintZ(&buf, "{s}", .{robot.name}) catch "";

        render_nametag(name, pos.*, size.*);
    }
}

fn render_homes() void {
    const homes = Home.get_all() catch return;

    const padding = 10;

    for (homes) |home| {
        const pos = home.get_position() orelse continue;
        const size = home.get_size() orelse continue;

        const tile_x = ord_to_tile(pos.x);
        const tile_y = ord_to_tile(pos.y);

        rl.drawRectangle(
            tile_x + (padding / 2),
            tile_y + (padding / 2),
            (TILE_SIZE * ftoi(size.x)) - padding,
            (TILE_SIZE * ftoi(size.y)) - padding,
            .purple,
        );

        const player = home.get_player() orelse continue;

        var buf: [100]u8 = undefined;
        const name = std.fmt.bufPrintZ(&buf, "{s}'s Home", .{player.name}) catch "";

        render_nametag(name, pos.*, size.*);
    }
}

fn render_mouse(camera: *rl.Camera2D) void {
    const map = &globals.MAP;
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

pub fn get_mouse_world_position(camera: *rl.Camera2D) comp.Position {
    const mouse_pos = rl.getMousePosition();
    const world_mouse_pos = rl.getScreenToWorld2D(mouse_pos, camera.*);

    const tile_x = ftoi(world_mouse_pos.x / TILE_SIZE);
    const tile_y = ftoi(world_mouse_pos.y / TILE_SIZE);
    return .{ .x = itof(tile_x), .y = itof(tile_y) };
}

pub fn render_tilemap(camera: *rl.Camera2D, chunk_manager: *ChunkManager) void {
    const visible_chunks = chunk_manager.get_visible_chunks(camera);
    defer std.heap.page_allocator.free(visible_chunks);

    for (visible_chunks) |chunk| {
        render_chunk(chunk);
    }
}

fn render_chunk(chunk: Chunk) void {
    for (0..CHUNK_SIZE) |local_y| {
        for (0..CHUNK_SIZE) |local_x| {
            const tile_idx = local_y * CHUNK_SIZE + local_x;
            const tile = chunk.tiles[tile_idx];

            // Calculate world position
            const world_x = chunk.world_x + @as(i32, @intCast(local_x));
            const world_y = chunk.world_y + @as(i32, @intCast(local_y));

            // Convert to screen coordinates
            const screen_x = world_x * TILE_SIZE;
            const screen_y = world_y * TILE_SIZE;

            switch (tile.base) {
                .mud => rl.drawRectangle(itoi(screen_x), itoi(screen_y), TILE_SIZE, TILE_SIZE, .dark_brown),
                .rock => rl.drawRectangle(itoi(screen_x), itoi(screen_y), TILE_SIZE, TILE_SIZE, .brown),
                .grass => rl.drawRectangle(itoi(screen_x), itoi(screen_y), TILE_SIZE, TILE_SIZE, .dark_green),
                .coal => rl.drawRectangle(itoi(screen_x), itoi(screen_y), TILE_SIZE, TILE_SIZE, .dark_gray),
            }
        }
    }
}

fn itoi(x: anytype) i32 {
    return @as(i32, @intCast(x));
}

pub fn render_nametag(entity_name: []const u8, pos: comp.Position, size: comp.Size) void {
    const font_size = 14;
    const padding = 6;
    const verical_offset = 8;

    var buf: [100]u8 = undefined;
    const name = std.fmt.bufPrintZ(&buf, "{s}", .{entity_name}) catch "";

    const name_width = rl.measureText(name, font_size);

    const tag_width = name_width + (padding * 2);
    const tag_height = font_size + (padding * 2);

    const entity_screen_x = ord_to_tile(pos.x);
    const entity_screen_y = ord_to_tile(pos.y);

    const entity_screen_width = ftoi(size.x) * TILE_SIZE;
    const tag_x = entity_screen_x + ftoi(itof(entity_screen_width - tag_width) / 2);
    const tag_y = entity_screen_y - tag_height - verical_offset;
    const shadow_offset = 2;

    // shadow
    rl.drawRectangle(
        tag_x + shadow_offset,
        tag_y + shadow_offset,
        tag_width,
        tag_height,
        rl.Color{ .r = 0, .g = 0, .b = 0, .a = 60 },
    );

    // background
    rl.drawRectangle(
        tag_x,
        tag_y,
        tag_width,
        tag_height,
        rl.Color{ .r = 40, .g = 44, .b = 52, .a = 220 },
    );

    // border
    rl.drawRectangleLines(
        tag_x,
        tag_y,
        tag_width,
        tag_height,
        rl.Color{ .r = 200, .g = 200, .b = 200, .a = 180 },
    );

    // Text
    rl.drawText(
        name,
        tag_x + padding,
        tag_y + padding,
        font_size,
        rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
    );
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

fn ord_to_tile(num: f32) i32 {
    return toi(num) * TILE_SIZE;
}

fn toi(x: anytype) i32 {
    return @as(i32, @intFromFloat(x));
}
