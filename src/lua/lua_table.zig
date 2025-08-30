const zlua = @import("zlua");
const Lua = zlua.Lua;
pub const TableField = struct {
    name: []const u8,
    value: TableValue,
};

pub const TableValue = union(enum) {
    string: []const u8,
    integer: c_long,
    number: f64,
    boolean: bool,
};

pub fn add_lua_table(
    L: *Lua,
    table_name: []const u8,
    fields: []const TableField,
) void {
    L.newTable();
    for (fields) |field| {
        switch (field.value) {
            .string => |s| {
                _ = L.pushString(s);
                L.setField(-2, field.name);
            },
            .integer => |i| {
                L.pushInteger(i);
                L.setField(-2, field.name);
            },
            .number => |n| {
                L.pushNumber(n);
                L.setField(-2, field.name);
            },
            .boolean => |b| {
                L.pushBoolean(b);
                L.setField(-2, field.name);
            },
        }
    }

    L.setGlobal(table_name);
}
