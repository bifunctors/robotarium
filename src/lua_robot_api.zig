const std = @import("std");
const ecs = @import("ecs");
const zlua = @import("zlua");
const comp = @import("component.zig");
const Robot = @import("robot.zig").Robot;
const Lua = zlua.Lua;

pub fn lua_robot_forward(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        std.debug.print("forward() must be called with : syntax", .{});
        return 0;
    }

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        std.debug.print("Could not get robot ID from table\n", .{});
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
        std.debug.print("move(direction) must be called with : syntax", .{});
        return 0;
    }

    const direction = L.toString(2) catch {
        std.debug.print("Move() requires direction\n", .{});
        return 0;
    };

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        std.debug.print("Could not get robot ID from table\n", .{});
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
        std.debug.print("canMove(direction) must be called with : syntax\n", .{});
        return 0;
    }

    // Get the string and copy it immediately
    const direction_ptr = L.toString(2) catch {
        std.debug.print("canMove() requires direction\n", .{});
        return 0;
    };

    // Copy to a stack buffer to avoid GC issues
    var direction_buf: [64]u8 = undefined;
    const direction = std.fmt.bufPrint(&direction_buf, "{s}", .{direction_ptr}) catch {
        std.debug.print("Direction string too long\n", .{});
        return 0;
    };

    std.debug.print("Direction: {s}\n", .{direction});

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        std.debug.print("Could not get robot ID from table\n", .{});
        L.pop(1);
        return 0;
    };
    L.pop(1);

    std.debug.print("ID: {}\n", .{id});

    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse {
        L.pushBoolean(false);
        return 1;
    };

    const can_move = robot.can_move(direction);
    L.pushBoolean(can_move);
    return 1; // Return 1 since we pushed a value
}
