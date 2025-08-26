const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const lua = @import("lua.zig");
const comp = @import("component.zig");
const ecs = @import("ecs");
const tilemap = @import("tilemap.zig");
const renderer = @import("render.zig");
const Player = @import("game/player.zig").Player;
const print = std.debug.print;

pub const WIDTH = 1500;
pub const HEIGHT = 800;

var camera = rl.Camera2D{
    .target = rl.Vector2.init(
        (tilemap.TILEMAP_WIDTH * tilemap.TILE_SIZE) / 2,
        (tilemap.TILEMAP_WIDTH * tilemap.TILE_SIZE) / 2,
    ),
    .offset = rl.Vector2.init(WIDTH / 2, HEIGHT / 2),
    .rotation = 0,
    .zoom = 0.5,
};

pub fn main() anyerror!void {
    init_raylib();
    defer rl.closeWindow();

    comp.init_registry(ecs.Registry.init(std.heap.page_allocator));

    const map = try tilemap.generate_map();

    const home_id = try Player.init("Bilbo Baggings");

    try lua.init_lua(home_id);
    defer lua.deinit_lua() catch unreachable;

    try lua.lua_main();

    var last_frame_time = rl.getTime();
    var second_timer: f32 = 0;

    while (!rl.windowShouldClose()) {
        const current_time = rl.getTime();
        const dt: f32 = @as(f32, @floatCast(current_time - last_frame_time)) * 1;
        last_frame_time = current_time;

        second_timer += dt;

        if (second_timer >= 1) {
            try lua.lua_loop();
            second_timer = 0;
        }

        input();

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        rl.beginMode2D(camera);

        renderer.render(&map, &camera);

        rl.endMode2D();

        rl.drawFPS(20, 20);
    }
}

fn input() void {
    if (rl.isKeyPressed(.q))
        std.process.exit(0);

    camera.zoom = std.math.exp(std.math.log(f32, std.math.e, camera.zoom) + (rl.getMouseWheelMove() * 0.1));
    if (camera.zoom > 2) camera.zoom = 2;
    if (camera.zoom < 0.1) camera.zoom = 0.1;

    if (rl.isKeyDown(.d))
        camera.target.x += 2;
    if (rl.isKeyDown(.l))
        camera.target.x += 2;

    if (rl.isKeyDown(.a))
        camera.target.x -= 2;
    if (rl.isKeyDown(.h))
        camera.target.x -= 2;

    if (rl.isKeyDown(.w))
        camera.target.y -= 2;
    if (rl.isKeyDown(.k))
        camera.target.y -= 2;

    if (rl.isKeyDown(.s))
        camera.target.y += 2;
    if (rl.isKeyDown(.j))
        camera.target.y += 2;

    if (rl.isMouseButtonDown(.middle)) {
        var delta = rl.getMouseDelta();
        delta = rl.Vector2.scale(delta, -1.0 / camera.zoom);
        camera.target = rl.Vector2.add(camera.target, delta);
    }
}

fn init_raylib() void {
    rl.initWindow(WIDTH, HEIGHT, "Scan");
    rl.setTargetFPS(120);
}
