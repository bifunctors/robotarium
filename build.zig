const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "scan",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });


    // External Dependencies

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const lua_dep = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
    });

    const ecs_dep = b.dependency("entt", .{
        .target = target,
        .optimize = optimize,
    });

    const known_folders_dep = b.dependency("known_folders", .{
        .target = target,
        .optimize = optimize,
    });


    // Internal Modules

    const log_dep = b.addModule("log", .{
        .root_source_file = b.path("src/utils/log.zig"),
    });


    // This adds the known-folders module to the executable which can then be imported with `@import("known-folders")`

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    const known_folders = known_folders_dep.module("known-folders");
    const ecs = ecs_dep.module("zig-ecs");

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("ecs", ecs);
    exe.root_module.addImport("zlua", lua_dep.module("zlua"));
    exe.root_module.addImport("raygui", raygui);
    exe.root_module.addImport("kfolders", known_folders);
    exe.root_module.addImport("log", log_dep);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
