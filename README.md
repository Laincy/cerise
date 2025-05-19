*Cerise* is a WIP chess engine built in Zig. It's a learning project of mine that I've been working on in stints.  At the moment, I am working on handcrafted evaluation, but do plan on implementing NNUE once I have a strong enough base with HCE.

## Features

- [ ] Comptime Caching: Currently, compile times are long because we are generating PEXT based magic bitboards on every compile. I hope to implement some way to cache these values as they should rarely, if ever, change.
- [ ] Move Generation
  - [ ] PERFT Testing
  - [x] Magic Bitboards
  - [x] Make/Unmake
- [ ] Evaluation Function
  - [ ] Material
  - [ ] Piece-Square Tables
  - [ ] Mobility
- [ ] Opening Book
- [x] FEN Parsing
- [ ] UCI Protocol
