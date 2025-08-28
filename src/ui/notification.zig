const std = @import("std");
const rl = @import("raylib");
const main = @import("../main.zig");
const utof = @import("../utils/utils.zig").utof;


pub const Notification = struct {
    msg: []const u8,
    duration: f32,
    timer: f32,

    pub var Notifications: std.ArrayList(Notification) = std.ArrayList(Notification){};
};

pub const NotificationRenderer = struct {
    pub const NOTIF_WIDTH: i32 = 300;
    pub const NOTIF_HEIGHT: i32 = 50;
    pub const NOTIF_MARGIN: i32 = 10;
    pub const NOTIF_PADDING: i32 = 15;
    pub const FONT_SIZE: i32 = 20;
    pub const CORNER_RADIUS: f32 = 0.2;
    pub const CORNER_SEGMENTS: i32 = 8;

    pub fn easeOutQuart(t: f32) f32 {
        const inv = 1.0 - t;
        return 1.0 - inv * inv * inv * inv;
    }

    pub fn calculateAlpha(progress: f32) f32 {
        return if (progress > 0.8) (1.0 - progress) * 2.5 else 1.0;
    }

    pub fn calculateOffset(progress: f32) f32 {
        const ease_progress = easeOutQuart(@min(progress * 4.0, 1.0));
        return (1.0 - ease_progress) * 50.0;
    }
};

pub fn notify(msg: []const u8) !void {
    try Notification.Notifications.append(std.heap.page_allocator, Notification{
        .duration = 5,
        .msg = msg,
        .timer = 0,
    });
}
