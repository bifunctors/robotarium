const std = @import("std");
const zlua = @import("zlua");
const Robot = @import("../game/robot.zig").Robot;
const ecs = @import("ecs");
const robot_api = @import("lua_robot_api.zig");
const tilemap = @import("../tilemap.zig");
const file_contents = @import("lua_files.zig");
const comp = @import("../component.zig");
const log = @import("log");
const notify = @import("../ui/notification.zig").notify;
const kf = @import("kfolders");
const Lua = zlua.Lua;

var lua_state: *Lua = undefined;
var current_home_id: usize = 0;

const LuaErrors = error{NoUpdateFunction};

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

fn lua_notify(L: *Lua) callconv(.c) c_int {
    const msg = L.toString(1) catch return 1;
    notify(msg) catch log.err("Could Not Notify Message: {s}", .{msg});
    return 0;
}

fn register_lua_functions(L: *Lua) void {
    L.newTable();

    L.pushFunction(zlua.wrap(lua_create_robot));
    L.setField(-2, "createRobot");

    L.pushFunction(zlua.wrap(lua_print));
    L.setField(-2, "console");

    L.pushFunction(zlua.wrap(lua_notify));
    L.setField(-2, "notify");

    L.setGlobal("Game");
}
