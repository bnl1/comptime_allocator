# Comptime allocator
---

Comptime allocator provides a standard allocation interface for compile time allocations

## Usage
tested on 0.14.0
main.zig
```zig
    const comptime_allocator = @import("comptime_allocator.zig");

    pub fn main() !void {
        comptime var a: *i32 = undefined;
        comptime {
            a = try comptime_allocator.allocator.create(i32);
            a.* = 42;
        }
        std.debug.print("{}\n", .{a});
    }
```

## Example
```zig
const comptime_allocator = @import("comptime_allocator");

pub fn main() !void {
    const s = comptime blk: {
        const allocator = comptime_allocator.allocator;

        var list = std.ArrayList(u8).init(allocator);
        try list.appendSlice("Hello ");
        try list.appendSlice("world");

        break :blk try list.toOwnedSlice();
    };
    std.debug.print("{any}\n", .{s});
}
```
for more examples look into tests in src/comptime_allocator.zig


## Shortcomings
As of zig 0.14.0 this no longer compiles. For now, the solution is to use `ArrayListUnmanaged.initBuffer()` if all you need is ArrayList.
