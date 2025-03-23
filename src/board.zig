const std = @import("std");
const cell_mod = @import("cell.zig");
const Cell = cell_mod.Cell;

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

    pub fn generate_board(self: *Board) !void {
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
};
