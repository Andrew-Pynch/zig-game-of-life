const std = @import("std");
const board_mod = @import("board.zig");
const Board = board_mod.Board;

pub const ITERATIONS: i32 = 300;
pub const DELAY_MS: u64 = 15; // how long to delay between each iter
pub const WIDTH = 100;
pub const HEIGHT = 40;

const RunOptions = struct {
    save: bool,
    graph: bool,
    help: bool,
    headless: bool,
    save_path: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var options = RunOptions{
        .save = false,
        .graph = false,
        .help = false,
        .headless = false,
        .save_path = "entropy_data.csv",
    };

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Skip executable name
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            options.help = true;
        } else if (std.mem.eql(u8, arg, "--save")) {
            options.save = true;
        } else if (std.mem.eql(u8, arg, "--graph")) {
            options.graph = true;
            options.save = true; // Graph mode implies save mode
        } else if (std.mem.eql(u8, arg, "--headless")) {
            options.headless = true;
        }
    }

    if (options.help) {
        return printHelp();
    }

    var board = try Board.init(allocator, HEIGHT, WIDTH);
    defer board.deinit();

    try board.generate_random_board();

    // Variables to track entropy values for graphing
    var entropy_values = if (options.save or options.graph)
        try std.ArrayList(f64).initCapacity(allocator, @intCast(ITERATIONS))
    else
        std.ArrayList(f64).init(allocator);
    defer entropy_values.deinit();

    // Only show initial board if not in headless mode
    if (!options.headless) {
        std.debug.print("Initial board state:\n", .{});
        board.print();

        // sleep a bit to let user see the initial state
        std.time.sleep(1 * std.time.ns_per_s);

        std.debug.print("\nBeginning game of life simulation:\n", .{});
    }

    var i: i32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        // Clear terminal only when not in headless mode
        if (!options.headless) {
            _ = try std.io.getStdOut().writer().print("\x1B[2J\x1B[H", .{});
        }

        const entropy = board.calculate_board_entropy();

        // Store entropy values if saving
        if (options.save or options.graph) {
            try entropy_values.append(entropy);
        }

        // Print iteration info and board only when not in headless mode
        if (!options.headless) {
            std.debug.print("Iteration {}/{}\nEntropy: {}\n", .{ i + 1, ITERATIONS, entropy });
            board.print();
        }

        try board.update();

        // Add delay between iterations for visibility when not in headless mode
        if (!options.headless) {
            std.time.sleep(DELAY_MS * std.time.ns_per_ms);
        }
    }

    // Save entropy data to file if requested
    if (options.save) {
        try saveEntropyData(entropy_values, options.save_path);
        std.debug.print("\nEntropy data saved to {s}\n", .{options.save_path});
    }

    // Render ASCII graph if requested
    if (options.graph) {
        try renderEntropyGraph(entropy_values);
    }

    if (!options.headless) {
        std.debug.print("\nSimulation complete!\n", .{});
    }
}

fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\Game of Life Simulation
        \\
        \\Usage:
        \\  zig-game-of-life                Run simulation with visual display
        \\  zig-game-of-life --help         Display this help message
        \\  zig-game-of-life --save         Save entropy data to file (entropy_data.csv) with visual display
        \\  zig-game-of-life --graph        Save entropy data and display ASCII graph of entropy over time with visual display
        \\  zig-game-of-life --headless     Run simulation without visual display (faster execution)
        \\
        \\Multiple options can be combined, e.g.:
        \\  zig-game-of-life --graph --headless    Run simulation headless, save data, and show final graph
        \\
        \\Configuration (in main.zig):
        \\  ITERATIONS: {d} - Number of simulation steps
        \\  WIDTH: {d} - Width of the simulation grid
        \\  HEIGHT: {d} - Height of the simulation grid
        \\  DELAY_MS: {d} - Delay between simulation steps (ms)
        \\
    , .{ ITERATIONS, WIDTH, HEIGHT, DELAY_MS });
}

fn saveEntropyData(entropy_values: std.ArrayList(f64), file_path: []const u8) !void {
    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    var writer = file.writer();

    // Write header
    try writer.writeAll("iteration,entropy\n");

    // Write data rows
    for (entropy_values.items, 0..) |entropy, i| {
        var buffer: [100]u8 = undefined;
        const line = try std.fmt.bufPrint(&buffer, "{d},{d}\n", .{ i, entropy });
        try writer.writeAll(line);
    }
}

fn renderEntropyGraph(entropy_values: std.ArrayList(f64)) !void {
    const stdout = std.io.getStdOut().writer();

    // Graph dimensions
    const graph_height: usize = 20;
    const graph_width: usize = @min(entropy_values.items.len, 80);

    // Find min and max entropy values
    var min_entropy: f64 = 1.0;
    var max_entropy: f64 = 0.0;

    for (entropy_values.items) |entropy| {
        min_entropy = @min(min_entropy, entropy);
        max_entropy = @max(max_entropy, entropy);
    }

    // Add 10% padding
    const range = max_entropy - min_entropy;
    const padding = range * 0.1;
    min_entropy -= padding;
    max_entropy += padding;

    // Sample points to fit graph width
    const step_size: usize = if (entropy_values.items.len <= graph_width)
        1
    else
        entropy_values.items.len / graph_width;

    // Print graph title
    try stdout.print("\n\nEntropy Over Time\n", .{});
    try stdout.print("Min: {d:.4}, Max: {d:.4}\n\n", .{ min_entropy, max_entropy });

    // Create graph
    var graph = try std.ArrayList([]u8).initCapacity(std.heap.page_allocator, graph_height);
    defer graph.deinit();

    // Initialize graph with spaces
    for (0..graph_height) |_| {
        const row = try std.heap.page_allocator.alloc(u8, graph_width);
        @memset(row, ' ');
        try graph.append(row);
    }

    // Plot points
    var x: usize = 0;
    var idx: usize = 0;
    while (x < graph_width and idx < entropy_values.items.len) {
        const entropy = entropy_values.items[idx];

        // Map entropy to y position (0 = bottom of graph)
        const normalized = if (max_entropy > min_entropy)
            (entropy - min_entropy) / (max_entropy - min_entropy)
        else
            0.5;

        const y_position = graph_height - 1 - @as(usize, @intFromFloat(normalized * @as(f64, @floatFromInt(graph_height - 1))));

        if (y_position < graph_height) {
            graph.items[y_position][x] = '*';
        }

        x += 1;
        idx += step_size;
    }

    // Print y-axis labels and graph
    for (0..graph_height) |y| {
        if (y == 0) {
            try stdout.print(" {d:.2} |", .{max_entropy});
        } else if (y == graph_height - 1) {
            try stdout.print(" {d:.2} |", .{min_entropy});
        } else if (y == graph_height / 2) {
            const mid_val = min_entropy + (max_entropy - min_entropy) / 2.0;
            try stdout.print(" {d:.2} |", .{mid_val});
        } else {
            try stdout.print("      |", .{});
        }

        try stdout.writeAll(graph.items[y]);
        try stdout.writeAll("\n");

        // Free the row
        std.heap.page_allocator.free(graph.items[y]);
    }

    // Print x-axis
    try stdout.writeAll("      +");
    for (0..graph_width) |_| {
        try stdout.writeAll("-");
    }
    try stdout.writeAll("\n");

    // Print x-axis labels
    try stdout.writeAll("       0");
    try stdout.print("{s}{d}\n", .{ " " ** 40, ITERATIONS });
}
