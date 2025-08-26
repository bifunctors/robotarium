const std = @import("std");
const zlua = @import("zlua");
const Robot = @import("robot.zig").Robot;
const robot_api = @import("lua_robot_api.zig");
const comp = @import("component.zig");
const Lua = zlua.Lua;

var lua_state: *Lua = undefined;
const non_robot_names = [_][]const u8{
    "init",
    "game_api",
    "api",
    "robot_api"
};

const ROBOT_API_KEY = "robot_api";

pub fn init_lua() !void {
    lua_state = try Lua.init(std.heap.page_allocator);
    lua_state.openLibs();
    register_lua_functions(lua_state);
}

pub fn deinit_lua() !void {
    lua_state.deinit();
}

pub fn run_lua_init() !void {
    try lua_state.doFile("lua/init.lua");
}

pub fn run_lua_loop() !void {
    const path = "lua";
    const alloc = std.heap.page_allocator;

    lua_state.pushNil();
    lua_state.setGlobal("Robot");


    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(alloc);
    defer walker.deinit();

    outer: while(try walker.next()) |entry| {
        if(entry.kind != .file) continue;

        var it = std.mem.splitScalar(u8, entry.basename, '.');
        const first_part = it.first();
        const extension = it.next();

        if(extension == null) continue;
        if(!std.mem.eql(u8, extension.?, "lua")) continue;

        for(non_robot_names) |non_robot_name| {
            if(std.mem.eql(u8, non_robot_name, first_part))
                continue :outer;
        }

        // Robot for the file
        const robot = Robot.get_name(first_part) orelse continue;

        const initial_stack = lua_state.getTop();

        lua_state.newTable();

        lua_state.pushInteger(@as(c_long, @intCast(robot.id)));
        lua_state.setField(-2, "id");

        const robot_pos = robot.get_position() orelse &comp.Position{ .x = 0, .y = 0 };

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.x)));
        lua_state.setField(-2, "x");

        lua_state.pushInteger(@as(c_long, @intFromFloat(robot_pos.y)));
        lua_state.setField(-2, "y");

        lua_state.pushFunction(zlua.wrap(robot_api.lua_robot_forward));
        lua_state.setField(-2, "forward");

        lua_state.setGlobal("Robot");

        const allocator = std.heap.page_allocator;
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.path });
        defer allocator.free(full_path);

        var buf: [100]u8 = undefined;
        const file = try std.fmt.bufPrintZ(&buf, "{s}", .{full_path});

        try lua_state.doFile(file);

        lua_state.setTop(initial_stack);
    }
}

fn lua_create_robot(L: *Lua) callconv(.c) c_int {
    // Check if able to create robot
    const name = L.toString(1) catch return 1;

    const rand = std.crypto.random;
    const x = rand.intRangeAtMost(i8, -5, 5);
    const y = rand.intRangeAtMost(i8, -5, 5);

    _ = Robot.init(name, @floatFromInt(x), @floatFromInt(y)) catch {
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
