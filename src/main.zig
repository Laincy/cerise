const std = @import("std");
const util = @import("util.zig");

const parseFen = @import("parsing.zig").parseFen;

const Position = @import("representation.zig").Position;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) return error.ExpectedArgument;

    const pos = try parseFen(args[1]);

    try util.printFullBoard(&pos.pieces);
}

test {
    std.testing.refAllDecls(@This());
}
