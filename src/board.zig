const std = @import("std");
const cell_mod = @import("cell.zig");
const Cell = cell_mod.Cell;

pub const MAX_POSSIBLE_NEIGHBORHOOD_PATTERNS = 512; // 3x3 unique patterns = 2^9 = 512

pub const Board = struct {
    rows: i32,
    cols: i32,
    grid: [][]Cell,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, rows: i32, cols: i32) !Board {
        // Allocate memory for rows
        var grid = try allocator.alloc([]Cell, @as(usize, @intCast(rows)));

        // Allocate each column
        var i: usize = 0;
        while (i < @as(usize, @intCast(rows))) : (i += 1) {
            grid[i] = try allocator.alloc(Cell, @as(usize, @intCast(cols)));

            // Initialize cells
            var j: usize = 0;
            while (j < @as(usize, @intCast(cols))) : (j += 1) {
                grid[i][j] = Cell.init(@as(i32, @intCast(j)), @as(i32, @intCast(i)), false);
            }
        }

        return Board{
            .rows = rows,
            .cols = cols,
            .grid = grid,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Board) void {
        // Free each row
        for (self.grid) |row| {
            self.allocator.free(row);
        }
        // Free the grid
        self.allocator.free(self.grid);
    }

    // Get cell at specific coordinates
    pub fn get_cell(self: *Board, x: i32, y: i32) *Cell {
        return &self.grid[@as(usize, @intCast(y))][@as(usize, @intCast(x))];
    }

    // Print the current board state
    pub fn print(self: Board) void {
        var i: usize = 0;
        while (i < self.grid.len) : (i += 1) {
            var j: usize = 0;
            while (j < self.grid[i].len) : (j += 1) {
                std.debug.print("{}", .{self.grid[i][j]});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn generate_board_with_glider(self: *Board) !void {
        self.get_cell(1, 0).*.alive = true;
        self.get_cell(2, 1).*.alive = true;
        self.get_cell(0, 2).*.alive = true;
        self.get_cell(1, 2).*.alive = true;
        self.get_cell(2, 2).*.alive = true;
    }

    pub fn generate_random_board(self: *Board) !void {
        var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
        const random = prng.random();

        for (self.grid) |*row| {
            for (row.*) |*cell| {
                // 25% chance for each cell to be alive
                cell.*.alive = random.boolean() and random.boolean();
            }
        }
    }

    pub fn update(self: *Board) !void {
        // Create a temporary board to store the next state
        var next_board = try Board.init(self.allocator, self.rows, self.cols);
        defer next_board.deinit();

        // Apply Game of Life rules to each cell
        for (self.grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                const alive_neighbors = self.count_alive_neighbors(cell);
                var next_state = false;

                if (cell.alive) {
                    // Any live cell with fewer than two live neighbors dies (underpopulation)
                    // Any live cell with more than three live neighbors dies (overpopulation)
                    // Any live cell with two or three live neighbors lives
                    next_state = (alive_neighbors == 2 or alive_neighbors == 3);
                } else {
                    // Any dead cell with exactly three live neighbors becomes alive (reproduction)
                    next_state = (alive_neighbors == 3);
                }

                next_board.get_cell(@intCast(j), @intCast(i)).*.alive = next_state;
            }
        }

        // Copy the next state back to the current board
        for (self.grid, 0..) |row, i| {
            for (row, 0..) |_, j| {
                self.get_cell(@intCast(j), @intCast(i)).*.alive =
                    next_board.get_cell(@intCast(j), @intCast(i)).*.alive;
            }
        }
    }

    pub fn count_alive_neighbors(self: *Board, cell: Cell) i32 {
        var alive_count: i32 = 0;

        const cell_coords = cell.get_coordinates();
        const cell_row = cell_coords.y; // Fix: x is column, y is row
        const cell_col = cell_coords.x; // Fix: x is column, y is row

        var row_offset: i32 = -1;
        while (row_offset <= 1) : (row_offset += 1) {
            var col_offset: i32 = -1;
            while (col_offset <= 1) : (col_offset += 1) {
                // skip the current cell centered at 0, 0
                if (row_offset == 0 and col_offset == 0) continue;

                const neighbor_row = cell_row + row_offset;
                const neighbor_col = cell_col + col_offset;

                // check if the neighbor is within bounds
                if (neighbor_row >= 0 and neighbor_row < self.rows and
                    neighbor_col >= 0 and neighbor_col < self.cols)
                {
                    // get the neighbor cell
                    const neighbor = self.get_cell(neighbor_col, neighbor_row);

                    if (neighbor.alive) {
                        alive_count += 1;
                    }
                }
            }
        }

        return alive_count;
    }

    // calculates entropy of a single board state
    // commented out because it had the problem of exploding entropy values
    // later into the simulation when the board had many identical patterns
    // resolved in version below
    // pub fn calculate_board_entropy_v0(self: *Board) f64 {
    //     var pattern_count = std.AutoHashMap(u16, u32).init(self.allocator);
    //     defer pattern_count.deinit();
    //
    //     const total_cells: f64 = @as(f64, @floatFromInt(self.rows * self.cols));
    //     var alive_cells: f64 = 0;
    //
    //     // count alive cells and analyze 3x3 patterns
    //     var i: usize = 0;
    //     while (i < @as(usize, @intCast(self.rows))) : (i += 1) {
    //         var j: usize = 0;
    //         while (j < @as(usize, @intCast(self.cols))) : (j += 1) {
    //             const x = @as(i32, @intCast(j));
    //             const y = @as(i32, @intCast(i));
    //
    //             if (self.get_cell(x, y).is_alive()) {
    //                 alive_cells += 1;
    //             }
    //
    //             // calculate a hash for the 3x3 neighborhood pattern
    //             const pattern_hash = calculate_pattern_hash(self, x, y);
    //
    //             // count pattern occurences
    //             const entry = pattern_count.getOrPut(pattern_hash) catch unreachable;
    //             if (!entry.found_existing) {
    //                 entry.value_ptr.* = 0;
    //             }
    //             entry.value_ptr.* += 1;
    //         }
    //     }
    //
    //     // calculate shannon entropy from pattern distribution
    //     var shannon_entropy: f64 = 0;
    //     var pattern_iterator = pattern_count.iterator();
    //     const total_patterns: f64 = total_cells;
    //
    //     while (pattern_iterator.next()) |entry| {
    //         const p: f64 = @as(f64, @floatFromInt(entry.value_ptr.*)) / total_patterns;
    //         shannon_entropy -= p * std.math.log2(p);
    //     }
    //
    //     // combine with density entropy
    //     const density: f64 = alive_cells / total_cells;
    //     var density_entropy: f64 = 0;
    //
    //     if (density > 0 and density < 1) {
    //         density_entropy = -density * std.math.log2(density) - (1 - density) * std.math.log2(1 - density);
    //         // normalize to [0, 1]
    //         density_entropy /= 1.0;
    //     }
    //
    //     // weighted combination of entropy metrics
    //     return 0.7 * shannon_entropy + 0.3 * density_entropy;
    // }

    // updated entropy calculation for a given board state that factors in
    // max number of possible patterns within a board / clusters of neighborhoods
    // to avoid exploding entropy later in the simulation when board has many
    // identical clusters of patterns
    // NOTE: Patterns are calculated on a 3x3 neighborhood basis
    pub fn calculate_board_entropy(self: *Board) f64 {
        var pattern_count = std.AutoHashMap(u16, u32).init(self.allocator);
        defer pattern_count.deinit();

        const total_cells: f64 = @as(f64, @floatFromInt(self.rows * self.cols));
        var alive_cells: f64 = 0;
        var unique_patterns: u32 = 0;

        // count alive cells and analzye all 3x3 patterns within neighborhoods
        var i: usize = 0;
        while (i < @as(usize, @intCast(self.rows))) : (i += 1) {
            var j: usize = 0;
            while (j < @as(usize, @intCast(self.cols))) : (j += 1) {
                const x = @as(i32, @intCast(j));
                const y = @as(i32, @intCast(i));

                if (self.get_cell(x, y).is_alive()) {
                    alive_cells += 1;
                }

                // calculate the pattern hash for the neighborhood around this cell
                const pattern_hash = calculate_pattern_hash(self, x, y);

                // count pattern occurences
                const entry = pattern_count.getOrPut(pattern_hash) catch unreachable;
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                    unique_patterns += 1;
                }
                entry.value_ptr.* += 1;
            }
        }

        // calculate the shannon entropy from the distribution of patterns
        var shannon_entropy: f64 = 0;
        var patter_iterator = pattern_count.iterator();

        // use actual pattern occurences rather than cell counts like in v0 impl
        const actual_patterns: f64 = total_cells; // total pattern observations

        while (patter_iterator.next()) |entry| {
            const p: f64 = @as(f64, @floatFromInt(entry.value_ptr.*)) / actual_patterns;
            shannon_entropy -= p * std.math.log2(p);
        }

        // calculate theoretical max entropy for normalization
        const max_possible_patterns = calculate_max_patterns(self);
        const max_theoretical_entropy = std.math.log2(@as(f64, @floatFromInt(max_possible_patterns)));

        const normalize_shannon_entropy = if (max_theoretical_entropy > 0)
            shannon_entropy / max_theoretical_entropy
        else
            0;

        // combine with density entropy
        const density: f64 = alive_cells / total_cells;
        var density_entropy: f64 = 0;

        if (density > 0 and density < 1) {
            density_entropy = -density * std.math.log2(density) - (1 - density) * std.math.log2(1 - density);
            // already normalized to [0 , 1]
        }

        // log ratio of unique patterns to total cells as a measure of complexity
        const cells_count = @as(u32, @intCast(self.rows * self.cols));
        const min_value = @min(512, cells_count);
        const pattern_diversity = @as(f64, @floatFromInt(unique_patterns)) / @as(f64, @floatFromInt(min_value));

        // weighted combination of entropy metrics
        return 0.6 * normalize_shannon_entropy + 0.3 * density_entropy + 0.1 * pattern_diversity;
    }

    // Also fix the calculate_pattern_hash function
    fn calculate_pattern_hash(self: *Board, x: i32, y: i32) u16 {
        var hash: u16 = 0;
        var bit_position: u4 = 0;

        var row_idx: i32 = y - 1;
        while (row_idx <= y + 1) : (row_idx += 1) {
            var col_idx: i32 = x - 1;
            while (col_idx <= x + 1) : (col_idx += 1) {
                if (row_idx >= 0 and row_idx < self.rows and
                    col_idx >= 0 and col_idx < self.cols)
                {
                    if (self.get_cell(col_idx, row_idx).is_alive()) {
                        hash |= @as(u16, 1) << bit_position;
                    }
                }
                bit_position += 1;
            }
        }

        return hash;
    }

    // calculate the max possible number of unique 3x3 patterns in a board
    fn calculate_max_patterns(self: *Board) u32 {
        // for a 3x3 neighboardhood there are only 2^9 = 512 possible patterns
        // but the actual max is limited by the board size

        // count how many complete 3x3 neighborhoods can fit in the baord
        const effective_rows = if (self.rows >= 3) self.rows - 2 else 0;
        const effective_cols = if (self.cols >= 3) self.cols - 2 else 0;
        const max_neighborhoods = @as(u32, @intCast(effective_rows * effective_cols));

        return @min(MAX_POSSIBLE_NEIGHBORHOOD_PATTERNS, max_neighborhoods);
    }
};
