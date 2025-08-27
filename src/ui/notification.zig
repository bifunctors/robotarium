const std = @import("std");
const rl = @import("raylib");
const main = @import("../main.zig");
const utof = @import("../utils.zig").utof;

pub const Notification = struct {
    msg: []const u8,
    duration: f32,
    timer: f32,

    pub var Notifications: std.ArrayList(Notification) = std.ArrayList(Notification){};
};

pub fn notify(msg: []const u8) !void {
    try Notification.Notifications.append(std.heap.page_allocator, Notification{
        .duration = 5,
        .msg = msg,
        .timer = 0,
    });
}
