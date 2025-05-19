//! Functions for parsing external formats into representations
const std = @import("std");
const rep = @import("representation.zig");

const bitmasks = @import("bitmasks.zig");

const PositionParseError = error{ ExceedsMaximumLength, MissingField, InvalidPiece, NonExistentPlayer, EnpassantFormat, InvalidCastle, InvalidAlgebraic };

/// Parses Forsyth–Edwards Notation (FEN) into a position
pub fn parseFen(str: []const u8) PositionParseError!rep.Position {
    if (str.len > 92) return error.ExceedsMaximumLength;

    var pos = rep.Position{
        .pieces = [_]u64{0} ** 12,
        .white_move = true,
        .castle_flags = 0,
        .enpassant_square = null,
    };

    var iter = std.mem.splitScalar(u8, str, ' ');
    {
        const pieces = iter.next() orelse return error.MissingField;
        var index: u6 = 56;

        for (pieces) |c| {
            switch (c) {
                'P' => pos.pieces[0] |= bitmasks.square[index],
                'N' => pos.pieces[1] |= bitmasks.square[index],
                'B' => pos.pieces[2] |= bitmasks.square[index],
                'R' => pos.pieces[3] |= bitmasks.square[index],
                'Q' => pos.pieces[4] |= bitmasks.square[index],
                'K' => pos.pieces[5] |= bitmasks.square[index],

                'p' => pos.pieces[6] |= bitmasks.square[index],
                'n' => pos.pieces[7] |= bitmasks.square[index],
                'b' => pos.pieces[8] |= bitmasks.square[index],
                'r' => pos.pieces[9] |= bitmasks.square[index],
                'q' => pos.pieces[10] |= bitmasks.square[index],
                'k' => pos.pieces[11] |= bitmasks.square[index],

                '1' => {},
                '2' => index += 1,
                '3' => index += 2,
                '4' => index += 3,
                '5' => index += 4,
                '6' => index += 5,
                '7' => index += 6,
                '8' => index += 7,
                '/' => {
                    index &= ~@as(u6, 7);
                    if (index != 0) index -= 8;
                    continue;
                },
                else => return error.InvalidPiece,
            }
            if (index % 8 != 7) index += 1;
        }
    }

    pos.white_move = switch ((iter.next() orelse return error.MissingField)[0]) {
        'w' => true,
        'b' => false,
        else => return error.NonExistentPlayer,
    };

    for (iter.next() orelse return error.MissingField) |c| switch (c) {
        '-' => break,
        'K' => pos.castle_flags |= 0b0001,
        'Q' => pos.castle_flags |= 0b0010,
        'k' => pos.castle_flags |= 0b0100,
        'q' => pos.castle_flags |= 0b1000,
        else => return error.InvalidCastle,
    };

    const enpassant_str: []const u8 = iter.next() orelse return error.MissingField;

    pos.enpassant_square = if (enpassant_str[0] != '-') try parseAlg(enpassant_str) else null;

    return pos;
}

/// Parses an algebraic chess square
pub fn parseAlg(str: []const u8) PositionParseError!u6 {
    if (str.len != 2) return error.InvalidAlgebraic;

    var index: u6 = switch (str[0]) {
        'a' => 0,
        'b' => 1,
        'c' => 2,
        'd' => 3,
        'e' => 4,
        'f' => 5,
        'g' => 6,
        'h' => 7,
        else => return error.InvalidAlgebraic,
    };

    index += switch (str[1]) {
        '1' => 0,
        '2' => 8,
        '3' => 16,
        '4' => 24,
        '5' => 32,
        '6' => 40,
        '7' => 48,
        '8' => 56,
        else => return error.InvalidAlgebraic,
    };

    return index;
}

const testing = std.testing;

test "parse_fen" {
    try testing.expectEqual(rep.starting_position, parseFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"));

    // Random FEN strings to ensure parsing doesn't error
    _ = try parseFen("1k6/4b3/R3P2r/1Pr2P2/2pPpP2/5n2/1Pn5/1K6 w - - 0 1");
    _ = try parseFen("7B/5k2/4p3/3P2R1/1NP2p2/1r1N1P1b/2KP2Pp/8 w - - 0 1");
    _ = try parseFen("6B1/P6n/p1kb1Q1r/8/5p2/8/2ppKp2/3NN2b w - - 0 1");

    try testing.expectError(PositionParseError.MissingField, parseFen(""));
    try testing.expectError(PositionParseError.InvalidPiece, parseFen("3x4/k1Br4/5P2/1p2p3/P5P1/6PP/B4nrP/5K2 w - - 0 1"));
}
