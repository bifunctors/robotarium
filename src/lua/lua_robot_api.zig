const std = @import("std");
const ecs = @import("ecs");
const zlua = @import("zlua");
const comp = @import("../component.zig");
const log = @import("log");
const Robot = @import("../game/robot.zig").Robot;
const Direction = @import("../utils/direction.zig").Direction;
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

    const direction_str = L.toString(2) catch {
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
    const direction = Direction.from_str(direction_str);
    if (direction) |d| {
        robot.*.move(d);
    } else {
        log.err("No valid direction was given", .{});
    }

    return 0;
}

pub fn lua_robot_can_move(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("canMove() must be called with : synax. Example: robot:canMove(\"north\")", .{});
        return 0;
    }

    // Get the string and copy it immediately
    const direction_ptr = L.toString(2) catch {
        return 0;
    };

    var direction_buf: [64]u8 = undefined;
    const direction_str = std.fmt.bufPrint(&direction_buf, "{s}", .{direction_ptr}) catch {
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

    const direction = Direction.from_str(direction_str);

    if (direction == null) {
        log.err("No valid direction was given", .{});
        L.pushBoolean(false);
        return 1;
    }

    const can_move = robot.can_move(direction.?);
    L.pushBoolean(can_move);
    return 1; // Return 1 since we pushed a value
}

pub fn lua_robot_can_move_cooldown(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("canMoveCooldown() must be called with : synax. Example: robot:canMoveCooldown()", .{});
        return 0;
    }

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

    L.pushBoolean(robot.move_cooldown());
    return 1;
}

pub fn lua_robot_get_inventory(L: *Lua) callconv(.c) c_int {
    if (!L.isTable(1)) {
        log.err("inv() must be called with : synax. Example: robot:inv()", .{});
        return 0;
    }

    _ = L.getField(1, "id");
    const id = L.toInteger(-1) catch {
        log.err("Could not get robot ID from lua table", .{});
        L.pop(0);
        return 0;
    };

    L.pop(0);
    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse {
        return 0;
    };

    L.newTable();

    const inv = robot.inventory;
    const items = inv.items.items;

    var idx: c_int = 1;
    for (items) |item| {
        L.createTable(0, 2);
        _ = L.pushString(item.kind.to_string());
        L.setField(-2, "name");

        L.pushInteger(@as(c_int, @intCast(item.count)));
        L.setField(-2, "count");

        L.rawSetIndex(-2, idx);
        idx += 1;
    }

    return 1;
}

pub fn lua_robot_get_inventory_size(L: *Lua) callconv(.c) c_int {
    if(!L.isTable(1)) {
        log.err("invSize() must be called with : synax. Example: robot:invSize()", .{});
        return 0;
    }

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

    L.pushInteger(@intCast(robot.inventory.size.num()));
    return 1;
}
