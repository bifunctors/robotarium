const std = @import("std");
const rl = @import("raylib");
const Tile = @import("tile.zig").Tile;
const TILE_SIZE = @import("tilemap.zig").TILE_SIZE;
const MAP_WIDTH = @import("tilemap.zig").MAP_WIDTH;
const globals = @import("../globals.zig");

pub const CHUNK_SIZE = 32;

pub const Chunk = struct {
    tiles: [CHUNK_SIZE * CHUNK_SIZE]Tile,
    world_x: i64,
    world_y: i64,
    loaded: bool = false,
};

const TileBounds = struct {
    min_x: u64,
    max_x: u64,
    min_y: u64,
    max_y: u64,
};

pub const ChunkManager = struct {
    chunks: std.HashMap([2]i64, Chunk, std.hash_map.AutoContext([2]i64), std.hash_map.default_max_load_percentage),

    pub fn init() ChunkManager {
        return ChunkManager{
            .chunks = std.HashMap([2]i64, Chunk, std.hash_map.AutoContext([2]i64), std.hash_map.default_max_load_percentage).init(std.heap.page_allocator),
        };
    }

    pub fn calculate_visible_tile_bounds(camera: *rl.Camera2D) TileBounds {
        const screen_width = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const screen_height = @as(f32, @floatFromInt(rl.getScreenHeight()));

        const top_left = rl.getScreenToWorld2D(.{ .x = 0, .y = 0 }, camera.*);
        const bottom_right = rl.getScreenToWorld2D(.{ .x = screen_width, .y = screen_height }, camera.*);

        const padding = 1;

        const min_tile_x = @max(0, @as(i32, @intFromFloat(top_left.x / TILE_SIZE)) - padding);
        const max_tile_x = @min(MAP_WIDTH - 1, @as(i32, @intFromFloat(bottom_right.x / TILE_SIZE)) + padding);
        const min_tile_y = @max(0, @as(i32, @intFromFloat(top_left.y / TILE_SIZE)) - padding);
        const max_tile_y = @min(@as(i32, @intCast(globals.MAP.items.len / MAP_WIDTH)) - 1, @as(i32, @intFromFloat(bottom_right.y / TILE_SIZE)) + padding);

        return TileBounds{
            .min_x = @intCast(@max(0, min_tile_x)),
            .max_x = @intCast(@max(0, max_tile_x)),
            .min_y = @intCast(@max(0, min_tile_y)),
            .max_y = @intCast(@max(0, max_tile_y)),
        };
    }

    pub fn get_visible_chunks(self: *ChunkManager, camera: *rl.Camera2D) []Chunk {
        const bounds = calculate_visible_tile_bounds(camera);

        const min_chunk_x = @divFloor(@as(i32, @intCast(bounds.min_x)), CHUNK_SIZE);
        const max_chunk_x = @divFloor(@as(i32, @intCast(bounds.max_x)), CHUNK_SIZE);
        const min_chunk_y = @divFloor(@as(i32, @intCast(bounds.min_y)), CHUNK_SIZE);
        const max_chunk_y = @divFloor(@as(i32, @intCast(bounds.max_y)), CHUNK_SIZE);

        var visible_chunks = std.ArrayList(Chunk){};

        for (@intCast(min_chunk_y)..@intCast(max_chunk_y + 1)) |cy| {
            for (@intCast(min_chunk_x)..@intCast(max_chunk_x + 1)) |cx| {
                const chunk_key = [2]i64{ @intCast(cx), @intCast(cy) };
                if (self.chunks.get(chunk_key)) |chunk| {
                    visible_chunks.append(std.heap.page_allocator, chunk) catch continue;
                } else {
                    // Load chunk if not in memory
                    const new_chunk = self.load_chunk(@intCast(cx), @intCast(cy));
                    self.chunks.put(chunk_key, new_chunk) catch continue;
                    visible_chunks.append(std.heap.page_allocator, new_chunk) catch continue;
                }
            }
        }

        return visible_chunks.toOwnedSlice(std.heap.page_allocator) catch &[_]Chunk{};
    }

    fn load_chunk(_: *ChunkManager, chunk_x: i64, chunk_y: i64) Chunk {
        var chunk = Chunk{
            .tiles = undefined,
            .world_x = chunk_x * CHUNK_SIZE,
            .world_y = chunk_y * CHUNK_SIZE,
            .loaded = true,
        };

        for (0..CHUNK_SIZE) |local_y| {
            for (0..CHUNK_SIZE) |local_x| {
                const world_x = chunk.world_x + @as(i64, @intCast(local_x));
                const world_y = chunk.world_y + @as(i64, @intCast(local_y));

                if (world_x >= 0 and world_x < MAP_WIDTH and
                    world_y >= 0 and world_y < @divExact(@as(i32, @intCast(globals.MAP.items.len)), MAP_WIDTH))
                {
                    const map_idx = @as(usize, @intCast(world_y * MAP_WIDTH + world_x));
                    chunk.tiles[local_y * CHUNK_SIZE + local_x] = globals.MAP.items[map_idx];
                }
            }
        }
        return chunk;
    }
};
