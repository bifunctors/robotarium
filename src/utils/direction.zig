const std = @import("std");
const Position = @import("../component.zig").Position;
pub const Direction = enum {
    forward,
    backward,
    left,
    right,

    pub fn get_relative_pos(dir: Direction) Position {
        return switch (dir) {
            .forward => .{ .x = 0, .y = -1 },
            .backward => .{ .x = 0, .y = 1 },
            .left => .{ .x = -1, .y = 0 },
            .right => .{ .x = 1, .y = 0 },
        };
    }

    pub fn from_str(str: []const u8) ?Direction {
        if(str.len > 10) return null;

        var out_str: [10]u8 = undefined;
        const lower_str = std.ascii.lowerString(&out_str, str);
        if(std.mem.eql(u8, lower_str, "north"))
            return .forward;
        if(std.mem.eql(u8, lower_str, "south"))
            return .backward;
        if(std.mem.eql(u8, lower_str, "west"))
            return .left;
        if(std.mem.eql(u8, lower_str, "east"))
            return .right;

        return null;

    }
};
