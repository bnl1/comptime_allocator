# Comptime allocator
---

Comptime allocator provides a standard allocation interface for compile time allocations

## Usage
tested on 0.12.0-dev.1769+bf5ab5451
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
The only structures I managed to make it work for are std.ArrayList and parsing json, now that doesn't
mean it doesn't work for the others, but I woudn't hold my breath. You can try make it work, but most
problems are inherent to how zig works and std implementation, but if you find other structures it
works on, I would like to know about it.

It doesn't work for std.HashMap

std.ArrayList, even when using comptime_allocator isn't possible to use with comptime types like
`comptime_int` or `type` (solution for this would be to create a special comptime ArrayList that such types
supports, if possible).
