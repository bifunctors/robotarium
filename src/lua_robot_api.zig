const std = @import("std");
const ecs = @import("ecs");
const zlua = @import("zlua");
const comp = @import("component.zig");
const Robot = @import("robot.zig").Robot;
const Lua = zlua.Lua;


pub fn lua_robot_forward(L: *Lua) callconv(.c) c_int {

    _ = L.getGlobal("Robot") catch {
        std.debug.print("Could not get global robot\n", .{});
        return 0;
    };
    _ = L.getField(-1, "id");


    const id = L.toInteger(-1) catch {
        L.pop(2);
        std.debug.print("Could not get integer L\n", .{});
        return 0;
    };

    L.pop(2);

    const robot = Robot.get_id(@as(usize, @intCast(id))) orelse return 0;
    robot.*.forward();

    return 0;
}
