//! Types and methods representing board state and how it changes

const std = @import("std");
const bitmasks = @import("bitmasks.zig");

pub const starting_position = Position{
    .pieces = .{
        0xff00,
        0x42,
        0x24,
        0x81,
        0x8,
        0x10,
        0xff000000000000,
        0x4200000000000000,
        0x2400000000000000,
        0x8100000000000000,
        0x800000000000000,
        0x1000000000000000,
    },
    .castle_flags = 0b1111,
    .enpassant_square  = null,
    .white_move = true,
};

/// A representation of a given posiition on a chess board.
pub const Position = struct {
    pieces: [12]u64,
    white_move: bool,
    enpassant_square: ?u6,
    ///kqKQ
    castle_flags: u4,

    pub fn makeMove(self: *Position, frame: *const MoveFrame) void {
        var total_change: u64 = 0;

        for (frame.pieces) |piece_change| {
            std.debug.assert(piece_change <= 12, "Invalid piece in PieceChange");

            if (piece_change.piece == 12) break;

            const change_board = piece_change.generateChangeBoard();

            self.pieces[piece_change.piece] ^= change_board;

            total_change |= change_board;
        }

        // handle castle flags
        self.castle_flags &= ~(bitmasks.pext(total_change, 0x8100000000000081));

        // handle enpassant changes
        if (frame.pieces[0].piece == 0 and frame.pieces[0].origin >> 3 == 1 and frame.pieces[0].target >> 3 == 3) {
            self.enpassant_square = frame.pieces[0].origin + 8;
        } else if (frame.pieces[0].piece == 6 and frame.piece[0].origin >> 3 == 6 and frame.pieces[0].target >> 3 == 4) {
            self.enpassant_square = frame.pieces[0].origin - 8;
        } else self.enpassant_square = null;

        self.white_move = !self.white_move;
    }

    pub fn unmakeMove(self: *Position, frame: *const MoveFrame) void {
        for (frame.pieces) |piece_change| {
            std.debug.assert(piece_change <= 12, "Invalid piece in PieceChange");

            if (piece_change.piece == 12) break;

            self.pieces[piece_change.piece] ^= piece_change.generateChangeBoard();
        }

        self.enpassant_square = frame.prev_enpasant;

        self.white_move = !self.white_move;
    }
};

/// The changes an individual piece undergoes. If the piece is captured or the
/// result of a promotion it has same origin and target values.
pub const PieceChange = packed struct {
    piece: u4,
    origin: u6,
    target: u6,

    pub inline fn generateChangeBoard(self: *const PieceChange) u64 {
        return bitmasks.square[self.origin] | bitmasks.square[self.target];
    }
};

/// A reversible move made ona given position.
pub const MoveFrame = struct {
    /// First value always exists, but for the second and third are null if piece =12
    pieces: [3]PieceChange,
    prev_castle: u4,
    prev_enpasant: ?u6,
};
