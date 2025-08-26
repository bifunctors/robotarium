const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const lua = @import("lua.zig");
const comp = @import("component.zig");
const ecs = @import("ecs");
const tilemap = @import("tilemap.zig");
const renderer = @import("render.zig");
const print = std.debug.print;

pub const WIDTH = 1500;
pub const HEIGHT = 800;

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

    comp.init_registry(ecs.Registry.init(std.heap.page_allocator));

    const map = try tilemap.generate_map();

    try lua.init_lua();
    defer lua.deinit_lua() catch unreachable;

    try lua.run_lua_init();

    try lua.run_lua_loop();

    while (!rl.windowShouldClose()) {
        input();

        if (camera.zoom > 2) camera.zoom = 2;
        if (camera.zoom < 0.3) camera.zoom = 0.3;

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        rl.beginMode2D(camera);

        renderer.render(&map);

        rl.endMode2D();
    }
}

fn input() void {
    if(rl.isKeyPressed(.q))
        std.process.exit(0);

    camera.zoom = std.math.exp(std.math.log(f32, std.math.e, camera.zoom) + (rl.getMouseWheelMove()*0.1));

    if(rl.isKeyDown(.d))
        camera.target.x += 2;
    if(rl.isKeyDown(.l))
        camera.target.x += 2;

    if(rl.isKeyDown(.a))
        camera.target.x -= 2;
    if(rl.isKeyDown(.h))
        camera.target.x -= 2;

    if(rl.isKeyDown(.w))
        camera.target.y -= 2;
    if(rl.isKeyDown(.k))
        camera.target.y -= 2;

    if(rl.isKeyDown(.s))
        camera.target.y += 2;
    if(rl.isKeyDown(.j))
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
