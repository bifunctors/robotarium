const std = @import("std");
const Tile = @import("map/tile.zig").Tile;

// Global State cause why not


pub var TICK: u64 = 0;
pub const TIME_PER_TICK: f32 = 0.01;

pub var MAP = std.ArrayList(Tile){};
