pub const Robot = struct {
    name: []const u8,

    fn init(name: []const u8) Robot {
        return Robot{
            .name = name
        };
    }
};
