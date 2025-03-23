const std = @import("std");
const board_mod = @import("board.zig");
const Board = board_mod.Board;

pub const ITERATIONS: i32 = 100000;
pub const DELAY_MS: u64 = 25; // Delay between iterations in milliseconds

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a board with arbitrary dimensions
    var board = try Board.init(allocator, 40, 150);
    defer board.deinit();

    // Option 1: Set specific pattern (glider)
    // board.get_cell(1, 0).*.alive = true;
    // board.get_cell(2, 1).*.alive = true;
    // board.get_cell(0, 2).*.alive = true;
    // board.get_cell(1, 2).*.alive = true;
    // board.get_cell(2, 2).*.alive = true;

    // Option 2: Generate a random board
    try board.generate_board();

    // Print the initial state
    std.debug.print("Initial board state:\n", .{});
    board.print();

    // Sleep a bit to let user see the initial state
    std.time.sleep(1 * std.time.ns_per_s);

    std.debug.print("\nBeginning game of life simulation:\n", .{});

    // Run the simulation for a fixed number of iterations
    var i: i32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        // Clear the terminal (Unix-like systems)
        _ = try std.io.getStdOut().writer().print("\x1B[2J\x1B[H", .{});

        // Print iteration number
        std.debug.print("Iteration {}/{}\n", .{ i + 1, ITERATIONS });

        // Print current board state
        board.print();

        // Update the board for the next generation
        try board.update();

        // Add a delay between iterations for visibility
        std.time.sleep(DELAY_MS * std.time.ns_per_ms);
    }

    std.debug.print("\nSimulation complete!\n", .{});
}
