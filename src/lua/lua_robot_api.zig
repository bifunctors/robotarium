const std = @import("std");
const ecs = @import("ecs");
const zlua = @import("zlua");
const comp = @import("../component.zig");
const log = @import("log");
const Robot = @import("../game/robot.zig").Robot;
const Lua = zlua.Lua;

pub fn lua_robot_forward(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("forward() must be called with : synax. Example: robot:forward()", .{});
        return 0;
    }

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        log.err("Could Not Get Robot ID From Lua Table", .{});
        L.pop(1);
        return 0;
    };
    L.pop(1);

    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse return 0;
    robot.*.forward();

    return 0;
}

pub fn lua_robot_move(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("move() must be called with : synax. Example: robot:move(\"north\")", .{});
        return 0;
    }

    const direction = L.toString(2) catch {
        log.err("move() requires a direction", .{});
        return 0;
    };

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        log.err("Could Not Get A Robot ID From The Lua Table", .{});
        L.pop(1);
        return 0;
    };
    L.pop(1);

    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse return 0;
    robot.*.move(direction);

    return 0;
}

pub fn lua_robot_can_move(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("canMove() must be called with : synax. Example: robot:canMove(\"north\")", .{});
        return 0;
    }

    // Get the string and copy it immediately
    const direction_ptr = L.toString(2) catch {
        log.err("canMove() lua method requires a direction", .{});
        return 0;
    };

    // Copy to a stack buffer to avoid GC issues
    var direction_buf: [64]u8 = undefined;
    const direction = std.fmt.bufPrint(&direction_buf, "{s}", .{direction_ptr}) catch {
        log.err("Direction String Was Too Long", .{});
        return 0;
    };

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        log.err("Could Not Get Robot ID From Lua Table", .{});
        L.pop(1);
        return 0;
    };
    L.pop(1);

    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse {
        L.pushBoolean(false);
        return 1;
    };

    const can_move = robot.can_move(direction);
    L.pushBoolean(can_move);
    return 1; // Return 1 since we pushed a value
}
