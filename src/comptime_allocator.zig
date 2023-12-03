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
        // who needs to resize if we can just create more memory
        return false;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn free(_: *anyopaque, buf: []u8, _: u8, _: usize) void {
    _ = buf;
    if (@inComptime()) {
        // I don't think we can do this
    } else @panic("Comptime allocator has to be called in comptime");
}

test "create" {
    comptime var a: *i32 = undefined;
    comptime {
        a = try allocator.create(i32);
        a.* = 42;
    }
    try std.testing.expect(a.* == 42);
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

test "comptime json" {
    const Struct = struct {
        id: u32,
        name: []const u8,
    };
    const value: Struct = comptime blk: {
        const slice =
            \\{
            \\  "id": 42,
            \\  "name": "bnl1"
            \\}
        ;

        const value = std.json.parseFromSliceLeaky(
            Struct,
            allocator,
            slice,
            .{},
        ) catch |err| @compileError(std.fmt.comptimePrint(
            "json parsing error {s}\n",
            .{@errorName(err)},
        ));
        break :blk value;
    };
    try std.testing.expectEqualDeep(
        Struct{ .id = 42, .name = "bnl1" },
        value,
    );
}
