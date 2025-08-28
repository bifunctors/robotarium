const comp = @import("../component.zig");
const globals = @import("../globals.zig");
const rl = @import("raylib");
const Home = @import("../game/home.zig").Home;
const Robot = @import("../game/robot.zig").Robot;
const BaseType = @import("base_type.zig").BaseType;
const Entity = @import("entity_type.zig").Entity;
const ftoi = @import("../utils/utils.zig").ftoi;
const ftou = @import("../utils/utils.zig").ftou;
const itou = @import("../utils/utils.zig").itou;
const MAP_WIDTH = @import("tilemap.zig").MAP_WIDTH;
const TILE_SIZE = @import("tilemap.zig").TILE_SIZE;

// Tiles should have a 'base' and sometimes an 'entity'
// Base -> Grass / Ore / Etc
// Entity -> Robot / Home / Tree
// In general an entity should be collidable
pub const Tile = struct {
    base: BaseType,

    pub fn from_pos(pos: comp.Position) *Tile {
        const idx = ftou(pos.x + (pos.y * MAP_WIDTH));
        return &globals.MAP.items[idx];
    }

    pub fn from_coord(x: i32, y: i32) *Tile {
        const idx = itou(x + (y * MAP_WIDTH));
        return &globals.MAP.items[idx];
    }

    pub fn from_coordf(x: f32, y: f32) *Tile {
        const idx = ftou(x + (y * MAP_WIDTH));
        return &globals.MAP.items[idx];
    }

    pub fn from_mouse(camera: *rl.Camera2D) ?Tile {
        const mouse_pos = rl.getMousePosition();
        const world_mouse_pos = rl.getScreenToWorld2D(mouse_pos, camera.*);

        const tile_x = ftoi(world_mouse_pos.x / TILE_SIZE);
        const tile_y = ftoi(world_mouse_pos.y / TILE_SIZE);

        const cols: i32 = MAP_WIDTH;
        const rows: i32 = @intCast(globals.MAP.items.len / MAP_WIDTH);

        if (tile_x >= 0 and tile_x < cols and tile_y >= 0 and tile_y < rows) {
            // Calculate the index in the map array
            const tile_index = @as(usize, @intCast(tile_y * cols + tile_x));

            // Return the tile type at this position
            return globals.MAP.items[tile_index];
        }

        // Return null if mouse is outside the tilemap bounds
        return null;
    }

    pub fn has_entity(pos: *const comp.Position) bool {
        return (Entity.get_tilef(pos.x, pos.y) != .NONE);
    }
};
