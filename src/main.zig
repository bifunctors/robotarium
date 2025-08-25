const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const lua = @import("lua.zig");
const comp = @import("component.zig");
const ecs = @import("ecs");
const tilemap = @import("tilemap.zig");
const print = std.debug.print;

pub const WIDTH = 800;
pub const HEIGHT = 450;

var camera = rl.Camera2D{
    .target = rl.Vector2.init((tilemap.TILEMAP_WIDTH * tilemap.TILE_SIZE) / 2,
    (tilemap.TILEMAP_WIDTH * tilemap.TILE_SIZE) / 2),
    .offset = rl.Vector2.init(WIDTH / 2, HEIGHT / 2),
    .rotation = 0,
    .zoom = 1
};

pub fn main() anyerror!void {
    init_raylib();
    defer rl.closeWindow();

    comp.ECS_REG = ecs.Registry.init(std.heap.page_allocator);

    const map = try tilemap.generate_map();

    try lua.run_lua_init();

    while (!rl.windowShouldClose()) {
        input();

        try lua.run_lua_loop();

        if (camera.zoom > 3.0) camera.zoom = 3.0;
        if (camera.zoom < 0.1) camera.zoom = 0.1;

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        rl.beginMode2D(camera);

        tilemap.render_tilemap(&map);

        rl.endMode2D();
    }
}

fn input() void {
    if(rl.isKeyPressed(.q))
        std.process.exit(0);

    camera.zoom = std.math.exp(std.math.log(f32, std.math.e, camera.zoom) + (rl.getMouseWheelMove()*0.1));

    if(rl.isKeyDown(.d))
        camera.target.x += 2;

    if(rl.isKeyDown(.a))
        camera.target.x -= 2;

    if(rl.isKeyDown(.w))
        camera.target.y -= 2;

    if(rl.isKeyDown(.s))
        camera.target.y += 2;

    if(rl.isMouseButtonDown(.left)) {
        var delta = rl.getMouseDelta();
        delta = rl.Vector2.scale(delta, -1.0/camera.zoom);
        camera.target = rl.Vector2.add(camera.target, delta);
    }
}

fn init_raylib() void {
    rl.initWindow(WIDTH, HEIGHT, "Scan");
    rl.setTargetFPS(240);
}
