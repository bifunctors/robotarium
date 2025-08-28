const std = @import("std");
const zlua = @import("zlua");
const Robot = @import("../game/robot.zig").Robot;
const ecs = @import("ecs");
const robot_api = @import("lua_robot_api.zig");
const tilemap = @import("../map/tilemap.zig");
const file_contents = @import("lua_files.zig");
const comp = @import("../component.zig");
const log = @import("log");
const globals = @import("../globals.zig");
const notify = @import("../ui/notification.zig").notify;
const kf = @import("kfolders");
const Lua = zlua.Lua;

var lua_state: *Lua = undefined;
var current_home_id: usize = 0;

const LuaErrors = error{NoUpdateFunction};

pub fn init(home_id: usize) !void {
    current_home_id = home_id;
    lua_state = try Lua.init(std.heap.page_allocator);
    lua_state.openLibs();
    register_lua_functions(lua_state);
}

pub fn deinit() !void {
    lua_state.deinit();
}

pub fn lua_main() !void {
    const config_folder = try kf.getPath(std.heap.page_allocator, .local_configuration);

    if (config_folder) |folder| {
        const config_path = try std.fs.path.join(
            std.heap.page_allocator,
            &[_][]const u8{ folder, "scan_game" },
        );
        const lua_config_path = try std.fs.path.join(
            std.heap.page_allocator,
            &[_][]const u8{ config_path, "lua" },
        );
        const main_lua_path = try std.fs.path.join(
            std.heap.page_allocator,
            &[_][]const u8{ lua_config_path, "main.lua" },
        );
        defer std.heap.page_allocator.free(config_path);
        var buf: [200]u8 = undefined;
        const path_formatted = std.fmt.bufPrintZ(&buf, "{s}", .{main_lua_path}) catch "";

        std.fs.makeDirAbsolute(config_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        std.fs.makeDirAbsolute(lua_config_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        try create_lua_api_files();

        std.fs.accessAbsolute(main_lua_path, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                const main_file = try std.fs.createFileAbsolute(main_lua_path, .{});
                defer main_file.close();
                try main_file.writeAll(file_contents.MAIN_API_LUA_FILE);
                log.debug("main.lua was not found at: {s}", .{path_formatted});
                log.debug("Created main.lua", .{});
            },
            else => return err,
        };

        try lua_state.doFile(path_formatted);
    } else {
        log.err("Could Not Open XDG_CONFIG Directory", .{});
    }
}

fn create_lua_api_files() !void {
    const config_folder = try kf.getPath(std.heap.page_allocator, .local_configuration);
    if (config_folder == null) return;

    const lua_config_path = try std.fs.path.join(
        std.heap.page_allocator,
        &[_][]const u8{ config_folder.?, "scan_game", "lua" },
    );
    defer std.heap.page_allocator.free(lua_config_path);

    const game_api_lua = try std.fs.path.join(
        std.heap.page_allocator,
        &[_][]const u8{ lua_config_path, ".game_api.lua" },
    );
    defer std.heap.page_allocator.free(game_api_lua);

    const globals_api_lua = try std.fs.path.join(
        std.heap.page_allocator,
        &[_][]const u8{ lua_config_path, ".globals_api.lua" },
    );
    defer std.heap.page_allocator.free(globals_api_lua);

    const robot_api_lua = try std.fs.path.join(
        std.heap.page_allocator,
        &[_][]const u8{ lua_config_path, ".robot_api.lua" },
    );
    defer std.heap.page_allocator.free(robot_api_lua);

    const game_api_file = try std.fs.createFileAbsolute(game_api_lua, .{});
    defer game_api_file.close();
    try game_api_file.writeAll(file_contents.GAME_API_LUA_FILE);

    const globals_api_file = try std.fs.createFileAbsolute(globals_api_lua, .{});
    defer globals_api_file.close();
    try globals_api_file.writeAll(file_contents.GLOBALS_API_LUA_FILE);

    const robot_api_file = try std.fs.createFileAbsolute(robot_api_lua, .{});
    defer robot_api_file.close();
    try robot_api_file.writeAll(file_contents.ROBOT_API_LUA_FILE);
}

pub fn lua_init() !void {
    create_robots_table();
    _ = lua_state.getGlobal("Init") catch {
        return;
    };

    if (lua_state.isFunction(-1)) {
        lua_state.call(.{ .args = 0, .results = 0 });
    } else {
        log.err("Init is not a function", .{});
        lua_state.pop(1);
    }
}

pub fn lua_loop() !void {
    create_robots_table();
    _ = lua_state.getGlobal("Update") catch {
        log.err("No Update() function was found in main.lua", .{});
        return LuaErrors.NoUpdateFunction;
    };

    if (lua_state.isFunction(-1)) {
        lua_state.call(.{ .results = 0, .args = 0 });
    } else {
        log.err("Update is not a function", .{});
        lua_state.pop(1);
    }
}

fn create_robots_table() void {
    lua_state.newTable();
    var idx: c_int = 1;

    const robots = Robot.get_all() catch return;

    for (robots) |robot| {
        lua_state.newTable();

        lua_state.pushInteger(@as(c_long, @intCast(robot.id)));
        lua_state.setField(-2, "id");

        _ = lua_state.pushString(robot.name);
        lua_state.setField(-2, "name");

        const robot_pos = robot.get_position() orelse continue;
        const relative_robot_pos = robot.get_relative_position() orelse continue;

        lua_state.pushInteger(@as(c_long, @intFromFloat(relative_robot_pos.x)));
        lua_state.setField(-2, "x");

        lua_state.pushInteger(@as(c_long, @intFromFloat(relative_robot_pos.y)));
        lua_state.setField(-2, "y");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.x)));
        lua_state.setField(-2, "worldX");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.y)));
        lua_state.setField(-2, "worldY");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_move));
        lua_state.setField(-2, "move");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_can_move));
        lua_state.setField(-2, "canMove");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_can_move_cooldown));
        lua_state.setField(-2, "moveCooldown");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_get_inventory));
        lua_state.setField(-2, "inventory");

        lua_state.rawSetIndex(-2, idx);
        idx += 1;
    }

    lua_state.setGlobal("robots");
}

fn lua_create_robot(L: *Lua) callconv(.c) c_int {
    // Check if able to create robot
    const name = L.toString(1) catch return 1;

    Robot.init(name, current_home_id) catch {
        log.err("Could Not Create Robot", .{});
        return 0;
    };

    log.info("Robot Named '{s}' Has Been Created", .{name});

    return 0;
}

fn lua_print(L: *Lua) callconv(.c) c_int {
    const msg = L.toString(1) catch return 1;

    log.info("> {s}", .{msg});

    return 0;
}

fn lua_get_tick(L: *Lua) callconv(.c) c_int {
    const tick = globals.TICK;
    L.pushInteger(@intCast(tick));
    return 1;
}

fn lua_notify(L: *Lua) callconv(.c) c_int {
    const msg = L.toString(1) catch return 0;
    notify(msg) catch log.err("Could Not Notify Message: {s}", .{msg});
    return 0;
}

// return id from robot

fn lua_get_robot(L: *Lua) callconv(.c) c_int {
    const name_or_id = L.toString(1) catch return 0;

    var possible_robot = Robot.get_name(name_or_id);
    if (possible_robot == null) {
        const id_num = std.fmt.parseInt(usize, name_or_id, 10) catch {
            return 0;
        };
        possible_robot = Robot.get_id(id_num);
        if (possible_robot == null) return 0;
    }

    const robot = possible_robot.?;

    log.info("Just got robot: {s}", .{robot.name});

    L.newTable();

    lua_state.pushInteger(@as(c_long, @intCast(robot.id)));
    lua_state.setField(-2, "id");

    _ = lua_state.pushString(robot.name);
    lua_state.setField(-2, "name");

    const robot_pos = robot.get_position() orelse return 0;
    const relative_robot_pos = robot.get_relative_position() orelse return 0;

    lua_state.pushInteger(@as(c_long, @intFromFloat(relative_robot_pos.x)));
    lua_state.setField(-2, "x");

    lua_state.pushInteger(@as(c_long, @intFromFloat(relative_robot_pos.y)));
    lua_state.setField(-2, "y");

    lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.x)));
    lua_state.setField(-2, "worldX");

    lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.y)));
    lua_state.setField(-2, "worldY");

    lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_move));
    lua_state.setField(-2, "move");

    lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_can_move));
    lua_state.setField(-2, "canMove");

    lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_can_move_cooldown));
    lua_state.setField(-2, "moveCooldown");

    lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_get_inventory));
    lua_state.setField(-2, "inventory");

    return 1;
}

fn register_lua_functions(L: *Lua) void {
    L.newTable();

    L.pushFunction(zlua.wrap(lua_create_robot));
    L.setField(-2, "createRobot");

    L.pushFunction(zlua.wrap(lua_get_robot));
    L.setField(-2, "getRobot");

    L.pushFunction(zlua.wrap(lua_print));
    L.setField(-2, "print");

    L.pushFunction(zlua.wrap(lua_get_tick));
    L.setField(-2, "getTick");

    L.pushFunction(zlua.wrap(lua_notify));
    L.setField(-2, "notify");

    L.setGlobal("Game");
}
