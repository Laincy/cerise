///! Comptime evaluated constants defining moves and attacks for all pieces
const std = @import("std");
const bitmasks = @import("bitmasks.zig");

pub const w_pawn_move: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;

    for (8..16) |i| res[i] = 0x10100 << @intCast(i);
    for (16..56) |i| res[i] = 0x100 << @intCast(i);

    break :blk res;
};

pub const b_pawn_move: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;

    for (48..56) |i| res[i] = 0x80800000000000 >> @intCast(63 - i);
    for (8..48) |i| res[i] = 0x80000000000000 >> @intCast(63 - i);

    break :blk res;
};

pub const w_pawn_attack: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0x280;
    for (8..56) |i| {
        res[i] |= base << @intCast(i);
        res[i] &= 0xff << (8 * ((i >> 3) + 1));
    }
    break :blk res;
};

pub const b_pawn_attack: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0x140000000000000;
    for (8..56) |i| {
        res[i] |= base >> @intCast(63 - i);
        res[i] &= 0xff << (8 * ((i >> 3) - 1));
    }
    break :blk res;
};

pub const knight_move: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    const base: u64 = 0xa1100110a; // Centered at 18
    for (0..64) |i| {
        switch (i) {
            0...17 => res[i] = base >> @intCast(18 - i),
            18 => res[18] = base,
            else => res[i] = base << @intCast(i - 18),
        }
        if (i & 7 <= 2) res[i] &= 0xf0f0f0f0f0f0f0f else if (i & 7 >= 6) res[i] &= 0xf0f0f0f0f0f0f0f0;
    }
    break :blk res;
};

pub const king_move = blk: {
    var res: [64]u64 = undefined;
    const base: u64 = 0x20502; // Centered at 9
    for (0..64) |i| {
        switch (i) {
            0...8 => res[i] = base >> @intCast(9 - i),
            9 => res[9] = base,
            else => res[i] = base << @intCast(i - 9),
        }

        if (i & 7 == 0) res[i] &= 0x303030303030303 else if (i & 7 == 7) res[i] &= 0xc0c0c0cc0c0c0c0;
    }
    break :blk res;
};

pub const MagicBitboard = struct {
    arr: []const u64,
    mask: u64,

    pub inline fn get(self: *const MagicBitboard, occupancy: u64) u64 {
        return self.arr[bitmasks.pext(occupancy, self.mask)];
    }
};

pub const rook_mbb: [64]MagicBitboard = blk: {
    @setEvalBranchQuota(std.math.maxInt(u32));

    var res: [64]MagicBitboard = undefined;

    for (0..64) |i| {
        var mask = bitmasks.ray_n[i] | bitmasks.ray_s[i] | bitmasks.ray_e[i] | bitmasks.ray_w[i];

        if (i & 7 != 0) mask &= 0xfefefefefefefefe;
        if (i & 7 != 7) mask &= 0x7f7f7f7f7f7f7f7f;

        if (i >> 3 != 0) mask &= 0xffffffffffffff00;
        if (i >> 3 != 7) mask &= 0x00ffffffffffffff;

        var arr = [_]u64{0xff} ** (@as(usize, 1) << @as(u64, @popCount(mask)));

        arr[0] = bitmasks.ray_n[i] | bitmasks.ray_s[i] | bitmasks.ray_e[i] | bitmasks.ray_w[i];

        var subset: u64 = (0 -% mask) & mask;

        while (subset != 0) : (subset = (subset -% mask) & mask) {
            var bb = arr[0];

            const north: u64 = subset & bitmasks.ray_n[i];
            if (north != 0) bb ^= bitmasks.ray_n[@ctz(north)];

            const south: u64 = subset & bitmasks.ray_s[i];
            if (south != 0) bb ^= bitmasks.ray_s[63 - @clz(south)];

            const east: u64 = subset & bitmasks.ray_e[i];
            if (east != 0) bb ^= bitmasks.ray_e[@ctz(east)];

            const west: u64 = subset & bitmasks.ray_w[i];
            if (west != 0) bb ^= bitmasks.ray_e[63 - @clz(west)];

            arr[bitmasks.pext(subset, mask)] = bb;
        }

        res[i] = MagicBitboard{
            .arr = &[0]u64{} ++ arr,
            .mask = mask,
        };
    }

    break :blk res;
};

test "rook magic bitboard" {
    try std.testing.expectEqual(0x404043b0404, rook_mbb[18].get(0x40000250000));
}

pub const bishop_mbb: [64]MagicBitboard = blk: {
    @setEvalBranchQuota(std.math.maxInt(u32));

    var res: [64]MagicBitboard = undefined;

    for (0..64) |i| {
        var mask: u64 = bitmasks.ray_ne[i] | bitmasks.ray_se[i] | bitmasks.ray_nw[i] | bitmasks.ray_sw[i];

        mask &= 0x007e7e7e7e7e7e00;

        var arr = [_]u64{0xff} ** (@as(usize, 1) << @as(u64, @popCount(mask)));

        arr[0] = bitmasks.ray_ne[i] | bitmasks.ray_se[i] | bitmasks.ray_nw[i] | bitmasks.ray_sw[i];

        var subset: u64 = (0 -% mask) & mask;

        while (subset != 0) : (subset = (subset -% mask) & mask) {
            var bb = arr[0];

            const north_east = subset & bitmasks.ray_ne[i];
            if (north_east != 0) bb ^= bitmasks.ray_ne[@ctz(north_east)];

            const south_east = subset & bitmasks.ray_se[i];
            if (south_east != 0) bb ^= bitmasks.ray_se[63 - @clz(south_east)];

            const north_west = subset & bitmasks.ray_nw[i];
            if (north_west != 0) bb ^= bitmasks.ray_nw[@ctz(north_west)];

            const south_west = subset & bitmasks.ray_sw[i];
            if (south_west != 0) bb ^= bitmasks.ray_sw[63 - @clz(south_west)];

            arr[bitmasks.pext(subset, mask)] = bb;
        }
        res[i] = MagicBitboard{
            .arr = &[0]u64{} ++ arr,
            .mask = mask,
        };
    }

    break :blk res;
};

test "bishop magic bitboard" {
    try std.testing.expectEqual(0x20100a000a11, bishop_mbb[18].get(0x200002000010));
}
