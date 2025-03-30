const std = @import("std");

const VTable = std.mem.Allocator.VTable;
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

const vtable = Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
    .remap = remap,
};

pub const allocator = std.mem.Allocator{
    .vtable = &vtable,
    .ptr = undefined,
};

fn alloc(_: *anyopaque, len: usize, alignment: Alignment, _: usize) ?[*]u8 {
    if (@inComptime()) {
        var array align(1 << @intFromEnum(alignment)) = [_]u8{undefined} ** len;
        return &array;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn resize(_: *anyopaque, _: []u8, _: Alignment, _: usize, _: usize) bool {
    if (@inComptime()) {
        // who needs to resize if we can just create more memory
        return false;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn remap(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) ?[*]u8 {
    if (@inComptime()) {
        // who needs to remap if we can just create more memory
        return null;
    } else @panic("Comptime allocator has to be called in comptime");
}

fn free(_: *anyopaque, buf: []u8, aligment: std.mem.Alignment, _: usize) void {
    _ = buf;
    _ = aligment;
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
        var array_list: std.ArrayListUnmanaged(u8) = .empty;

        try array_list.appendSlice(allocator, "Helloo");
        try array_list.appendSlice(allocator, "wworld!");

        try array_list.replaceRange(allocator, 5, 2, ", ");

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
