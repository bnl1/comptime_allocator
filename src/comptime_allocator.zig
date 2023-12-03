const std = @import("std");

const VTable = std.mem.Allocator.VTable;
const Allocator = std.mem.Allocator;

const vtable = Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
};

pub const allocator = std.mem.Allocator{
    .vtable = &vtable,
    .ptr = undefined,
};

fn alloc(_: *anyopaque, len: usize, _: u8, _: usize) ?[*]u8 {
    if (@inComptime()) {
        var array = [_]u8{undefined} ** len;
        return array[0..].ptr;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn resize(_: *anyopaque, buf: []u8, _: u8, new_len: usize, _: usize) bool {
    _ = buf;
    _ = new_len;
    if (@inComptime()) {
        return false;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn free(_: *anyopaque, buf: []u8, _: u8, _: usize) void {
    _ = buf;
    if (@inComptime()) {} else @panic("Comptime allocator has to be called in comptime");
}

test "comptime ArrayList" {
    const hello_world = comptime blk: {
        var array_list = std.ArrayList(u8).init(allocator);

        try array_list.appendSlice("Helloo");
        try array_list.appendSlice("wworld!");

        try array_list.replaceRange(5, 2, ", ");

        break :blk array_list.items;
    };
    try std.testing.expectEqualSlices(u8, "Hello, world!", hello_world);
}

// std.HashMap is not compatible with comptime_allocator
// test "comptime HashMap" {
//     const hash_map = comptime blk: {
//         var hash_map = std.AutoHashMap(i32, []const u8).init(allocator);

//         try hash_map.put(0, "zero");
//         try hash_map.put(3, "three");
//         try hash_map.put(10, "ten");
//         try hash_map.put(11, "eleven");
//         try hash_map.remove(3);

//         break :blk hash_map;
//     };

//     try std.testing.expectEqualSlices(u8, "eleven", hash_map.get(11).?);
//     try std.testing.expectEqualSlices(u8, "zero", hash_map.get(0).?);
//     try std.testing.expect(hash_map.get(3) == null);
// }
