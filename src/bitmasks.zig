//! Comptime evaluated values for various bitboard operations

const std = @import("std");

/// A mask for a specific square
pub const square: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| res[i] = 1 << @intCast(i);
    break :blk res;
};

pub const ray_n: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| res[i] = @as(u64, 0x0101010101010100) << @intCast(i);
    break :blk res;
};

pub const ray_s: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| res[i] = 0x0080808080808080 >> @intCast(63 - i);
    break :blk res;
};

pub const ray_e: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| {
        var tmp = 0xfe << @intCast(i);
        tmp &= 0xff << (8 * (i >> 3));
        res[i] = tmp;
    }
    break :blk res;
};

pub const ray_w: [64]u64 = blk: {
    var res: [64]u64 = undefined;
    for (0..64) |i| {
        var tmp = 0x7f00000000000000 >> @intCast(63 - i);
        tmp &= 0xff << (8 * (i >> 3));
        res[i] = tmp;
    }
    break :blk res;
};
pub const ray_ne: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    for (0..64) |i| {
        const n_dist: usize = 7 - (i >> 3);
        const e_dist: usize = 7 - (i & 7);

        const dist: usize = @min(n_dist, e_dist);

        if (dist == 0) continue;

        for (1..dist + 1) |j| res[i] |= square[i] << @intCast(j * 9);
    }
    break :blk res;
};

pub const ray_se: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    for (0..64) |i| {
        const s_dist: usize = i >> 3;
        const e_dist: usize = 7 - (i & 7);

        const dist: usize = @min(s_dist, e_dist);

        if (dist == 0) continue;

        for (1..dist + 1) |j| res[i] |= square[i] >> @intCast(j * 7);
    }
    break :blk res;
};

pub const ray_nw: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    for (0..64) |i| {
        const n_dist: usize = 7 - (i >> 3);
        const w_dist: usize = i & 7;

        const dist: usize = @min(n_dist, w_dist);

        if (dist == 0) continue;

        for (1..dist + 1) |j| res[i] |= square[i] << @intCast(j * 7);
    }
    break :blk res;
};

pub const ray_sw: [64]u64 = blk: {
    var res: [64]u64 = [_]u64{0} ** 64;
    for (0..64) |i| {
        const s_dist: usize = i >> 3;
        const w_dist: usize = i & 7;

        const dist: usize = @min(s_dist, w_dist);

        if (dist == 0) continue;

        for (1..dist + 1) |j| res[i] |= square[i] >> @intCast(j * 9);
    }
    break :blk res;
};

pub inline fn pext(src: u64, mask: u64) u64 {
    if (@inComptime()) {
        @setEvalBranchQuota(std.math.maxInt(u32));
        var result: u64 = 0;
        var m = mask;
        var i: std.math.Log2Int(u64) = 0;
        while (m > 0) : ({
            m &= m -% 1;
            i += 1;
        }) {
            result |= ((src >> @ctz(m)) & 1) << i;
        }
        return result;
    }

    return asm ("pext %[mask], %[src], %[ret]"
        : [ret] "=r" (-> u64),
        : [src] "r" (src),
          [mask] "r" (mask),
    );
}
