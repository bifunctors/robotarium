pub fn ftoi(x: f32) i32 {
    return @as(i32, @intFromFloat(x));
}

pub fn ftou(x: f32) usize {
    return @as(usize, @intFromFloat(x));
}

pub fn itof(x: i32) f32 {
    return @as(f32, @floatFromInt(x));
}
