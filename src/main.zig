const std = @import("std");
const board_mod = @import("board.zig");
const Board = board_mod.Board;

pub const ITERATIONS: i32 = 1000;
pub const DELAY_MS: u64 = 15; // how long to delay between each iter
pub const WIDTH = 100;
pub const HEIGHT = 40;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = try Board.init(allocator, HEIGHT, WIDTH);
    defer board.deinit();

    try board.generate_random_board();

    std.debug.print("Initial board state:\n", .{});
    board.print();

    // sleep a bit to let user see the initial state
    std.time.sleep(1 * std.time.ns_per_s);

    std.debug.print("\nBeginning game of life simulation:\n", .{});

    var i: i32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        // clear the terminal (Unix-like systems)
        _ = try std.io.getStdOut().writer().print("\x1B[2J\x1B[H", .{});

        const entropy = board.calculate_board_entropy();

        // print iteration number
        std.debug.print("Iteration {}/{}\nEntropy: {}\n", .{ i + 1, ITERATIONS, entropy });

        board.print();
        try board.update();

        // add a delay between iterations for visibility
        std.time.sleep(DELAY_MS * std.time.ns_per_ms);
    }

    std.debug.print("\nSimulation complete!\n", .{});
}
