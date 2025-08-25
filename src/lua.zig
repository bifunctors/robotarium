const std = @import("std");
const zlua = @import("zlua");
const Robot = @import("robot.zig").Robot;
const Lua = zlua.Lua;

pub fn run_lua_init() !void {
    var lua = try Lua.init(std.heap.page_allocator);
    defer lua.deinit();

    lua.openLibs();
    register_lua_functions(lua);

    try lua.doFile("lua/init.lua");
}

pub fn run_lua_loop() !void {
    var lua = try Lua.init(std.heap.page_allocator);
    defer lua.deinit();

    lua.openLibs();
    register_lua_functions(lua);

    try lua.doFile("lua/loop.lua");
}

fn lua_init_robot(L: *Lua) callconv(.c) c_int {
    // Check if able to create robot

    const name = L.toString(1) catch return 1;
    const pos_x = L.toNumber(2) catch return 1;
    const pos_y = L.toNumber(3) catch return 1;

    Robot.init(name, @floatCast(pos_x), @floatCast(pos_y));


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

    L.pushFunction(zlua.wrap(lua_init_robot));
    L.setField(-2, "init_robot");

    L.pushFunction(zlua.wrap(lua_print));
    L.setField(-2, "console");

    L.setGlobal("Game");
}
