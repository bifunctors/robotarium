const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const lua = @import("lua.zig");
const print = std.debug.print;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Scan Game");
    defer rl.closeWindow();

    rl.setTargetFPS(240);

    try lua.run_file();

    while (!rl.windowShouldClose()) {
        input();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
    }
}

fn input() void {
    if(rl.isKeyPressed(.q)) {
        std.process.exit(0);
    }
}

test "Config File Read" {}
