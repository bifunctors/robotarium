const std = @import("std");
const ecs = @import("ecs");
const zlua = @import("zlua");
const comp = @import("component.zig");
const Robot = @import("robot.zig").Robot;
const Lua = zlua.Lua;


pub fn lua_robot_forward(L: *Lua) callconv(.c) c_int {
    _ = L.getGlobal("Robot") catch return 0;
    _ = L.getField(-1, "ptr");

    if(!L.isUserdata(-1)) {
        L.pop(2);
        std.debug.print("Robot.ptr is not userdata\n", .{});
        return 0;
    }

    const robot = L.toUserdata(*Robot, -1) catch {
        L.pop(2);
        std.debug.print("Failed to get userdata\n", .{});
        return 0;
    };

    L.pop(2);

    robot.*.forward();

    return 0;
}
