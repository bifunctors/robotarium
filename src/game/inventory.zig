const std = @import("std");
const Item = @import("item.zig").Item;

pub const Inventory = struct {
    items: std.ArrayList(Item),
    size: InventorySize,

    pub fn init(size: InventorySize) !*Inventory {
        const inv = try std.heap.page_allocator.create(Inventory);
        inv.items = std.ArrayList(Item){};
        inv.size = size;
        return inv;
    }

    pub fn deinit(inventory: *Inventory) void {
        std.heap.page_allocator.destroy(inventory);
    }

    pub fn add(inventory: *Inventory, item: Item) void {
        // Get existing Item and add to it
        inventory.items.append(std.heap.page_allocator, item) catch return;
    }
};

pub const InventorySize = enum(usize) {
    large = 30,
    medium = 20,
    small = 10,
};
