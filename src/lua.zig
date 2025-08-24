const std = @import("std");
const zlua = @import("zlua");
const Lua = zlua.Lua;

pub fn run_file() !void {
    var lua = try Lua.init(std.heap.page_allocator); defer lua.deinit();

    lua.openLibs();
    register_lua_functions(lua);

    try lua.doFile("lua/init.lua");

    try lua.doFile("lua/loop.lua");
}

fn lua_move_forward(_: ?*zlua.LuaState) callconv(.c) c_int {
    return 0;
}

fn lua_init_robot(_: ?*zlua.LuaState) callconv(.c) c_int {

    return 0;
}


fn register_lua_functions(L: *Lua) void {
    L.newTable();

    L.pushFunction(lua_move_forward);
    L.setField(-2, "forward");

    L.pushFunction(lua_init_robot);
    L.setField(-2, "init_robot");

    L.setGlobal("Game");
}

