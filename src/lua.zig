const std = @import("std");
const zlua = @import("zlua");
const Robot = @import("robot.zig").Robot;
const ecs = @import("ecs");
const robot_api = @import("lua_robot_api.zig");
const tilemap = @import("tilemap.zig");
const comp = @import("component.zig");
const Lua = zlua.Lua;

var lua_state: *Lua = undefined;
var current_home_id: usize = 0;

pub fn init_lua(home_id: usize) !void {
    current_home_id = home_id;
    lua_state = try Lua.init(std.heap.page_allocator);
    lua_state.openLibs();
    register_lua_functions(lua_state);
}

pub fn deinit_lua() !void {
    lua_state.deinit();
}

pub fn lua_main() !void {
    try lua_state.doFile("lua/main.lua");
}

pub fn lua_loop() !void {

    const robots = Robot.get_all() catch return;

    for(robots) |robot| {
        robot.reset_turn();
    }


    create_robots_table();
    _ = lua_state.getGlobal("Update") catch {
        std.debug.print("No update() function found in main.lua\n", .{});
        return;
    };

    if(lua_state.isFunction(-1)) {
        lua_state.call(.{ .results = 0, .args = 0});
    } else {
        std.debug.print("Update is not a function\n", .{});
        lua_state.pop(1);
    }
}

fn create_robots_table() void {
    lua_state.newTable();
    var idx: c_int = 1;

    const robots = Robot.get_all() catch return;

    for(robots) |robot| {
        lua_state.newTable();

        lua_state.pushInteger(@as(c_long, @intCast(robot.id)));
        lua_state.setField(-2, "id");

        const robot_pos = robot.get_world_position() orelse comp.Position{ .x = 0, .y = 0 };

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot.relative_position.x)));
        lua_state.setField(-2, "x");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot.relative_position.y)));
        lua_state.setField(-2, "y");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.x)));
        lua_state.setField(-2, "worldX");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.y)));
        lua_state.setField(-2, "worldY");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_move));
        lua_state.setField(-2, "move");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_can_move));
        lua_state.setField(-2, "canMove");

        lua_state.rawSetIndex(-2, idx);
        idx += 1;
    }

    lua_state.setGlobal("robots");
}

fn lua_create_robot(L: *Lua) callconv(.c) c_int {
    // Check if able to create robot
    const name = L.toString(1) catch return 1;

    Robot.init(name, current_home_id) catch {
        std.debug.print("Could not create robot\n", .{});
        return 0;
    };

    std.debug.print("> Robot Named: {s} Has Been Created\n", .{name});

    return 0;
}

fn lua_print(L: *Lua) callconv(.c) c_int {
    const msg = L.toString(1) catch return 1;

    std.debug.print("> {s}\n", .{msg});

    return 0;
}

fn register_lua_functions(L: *Lua) void {
    L.newTable();

    L.pushFunction(zlua.wrap(lua_create_robot));
    L.setField(-2, "createRobot");

    L.pushFunction(zlua.wrap(lua_print));
    L.setField(-2, "console");

    L.setGlobal("Game");
}
