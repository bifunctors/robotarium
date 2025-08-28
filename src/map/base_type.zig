pub const BaseType = union(enum) {
    GRASS,
    ROCK,
    MUD,
    CONCRETE,

    pub fn to_string(this: *const BaseType) []const u8 {
        return switch (this.*) {
            .GRASS => "GRASS",
            .ROCK => "ROCK",
            .MUD => "MUD",
            .CONCRETE => "CONCRETE",
        };
    }
};
