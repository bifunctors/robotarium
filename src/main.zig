const std = @import("std");
const scan = @import("scan");
const rl = @import("raylib");
const rlgui = @import("raygui");
const lua = @import("lua/lua.zig");
const comp = @import("component.zig");
const ecs = @import("ecs");
const tilemap = @import("map/tilemap.zig");
const globals = @import("globals.zig");
const notify = @import("ui/notification.zig").notify;
const ftoi = @import("utils/utils.zig").ftoi;
const Robot = @import("game/robot.zig").Robot;
const Tile = @import("map/tile.zig").Tile;
const Entity = @import("map/entity_type.zig").Entity;
const log = @import("log");
const renderer = @import("render.zig");
const Player = @import("game/player.zig").Player;
const print = std.debug.print;

pub const WIDTH = 1500;
pub const HEIGHT = 800;

var camera = rl.Camera2D{
    .target = rl.Vector2.init(
        (tilemap.MAP_WIDTH * tilemap.TILE_SIZE) / 2,
        (tilemap.MAP_WIDTH * tilemap.TILE_SIZE) / 2,
    ),
    .offset = rl.Vector2.init(WIDTH / 2, HEIGHT / 2),
    .rotation = 0,
    .zoom = 0.5,
};

pub fn main() anyerror!void {
    init_raylib();
    defer rl.closeWindow();

    // Entity Component System
    comp.init_registry(ecs.Registry.init(std.heap.page_allocator));

    // Generates a random map, this will be procedurally generated in future
    // Probably should use some sort of noise function in the future aswell
    globals.MAP = try tilemap.generate_map();

    // Creating a player generates them a home automatically
    const home_id = try Player.init("Bilbo Baggings");

    // Creates lua state
    try lua.init_lua(home_id);
    defer lua.deinit_lua() catch unreachable;

    lua.lua_main() catch {
        log.err("Could Not Run main.lua", .{});
        return;
    };

    var last_frame_time = rl.getTime();
    var tick_timer: f32 = 0;
    var previus_tick: u64 = 0;

    while (!rl.windowShouldClose()) {
        const current_time = rl.getTime();
        // delta time
        const dt: f32 = @as(f32, @floatCast(current_time - last_frame_time)) * 1;
        last_frame_time = current_time;

        tick_timer += dt;

        if (tick_timer >= globals.TIME_PER_TICK) {
            previus_tick = globals.TICK;
            globals.TICK += 1;
            tick_timer = 0;
        }

        // Run every tick
        if (previus_tick > globals.TICK) {
            try lua.lua_loop();
        }

        // Systems Here
        try input_system();

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.white);

        {
            rl.beginMode2D(camera);
            defer rl.endMode2D();

            renderer.render(&camera);
        }

        renderer.render_notifications(dt);

        rl.drawFPS(20, 20);
    }
}

fn input_system() !void {
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

    if (rl.isMouseButtonPressed(.left)) {
        const tile = Tile.from_mouse(&camera);
        const mouse_pos = renderer.get_mouse_world_position(&camera);

        if (tile) |t| {
            const entity = Entity.get_tilef(mouse_pos.x, mouse_pos.y);
            const noficiation_msg = try std.fmt.allocPrint(
                std.heap.page_allocator,
                "{s} : {s}",
                .{ t.base.to_string(), entity.to_string() },
            );

            try notify(noficiation_msg);
        }
    }

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
