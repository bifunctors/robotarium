const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const lua = @import("lua.zig");
const comp = @import("component.zig");
const ecs = @import("ecs");
const print = std.debug.print;


pub fn main() anyerror!void {
    init_raylib();
    defer rl.closeWindow();

    comp.ECS_REG = ecs.Registry.init(std.heap.page_allocator);

    try lua.run_lua_init();

    while (!rl.windowShouldClose()) {
        input();

        rl.beginDrawing();
        defer rl.endDrawing();

        // Set this to run at 60 fps always
        try lua.run_lua_loop();

        // Draw world tile map
        // Iterate through rendering entities and draw them

        rl.clearBackground(.white);
    }
}

fn input() void {
    if(rl.isKeyPressed(.q)) {
        std.process.exit(0);
    }
}

fn init_raylib() void {
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "Scan Game");
    rl.setTargetFPS(240);
}
