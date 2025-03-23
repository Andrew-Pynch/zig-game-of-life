const std = @import("std");

pub const Cell = struct {
    x: i32,
    y: i32,
    alive: bool,
    pub fn format(self: Cell, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        if (self.alive) {
            try writer.print("█", .{}); // Unicode block character for alive cells
        } else {
            try writer.print("·", .{}); // Small dot for dead cells
        }
    }

    pub fn init(x: i32, y: i32, alive: bool) Cell {
        return Cell{ .x = x, .y = y, .alive = alive };
    }

    pub fn revive(self: Cell) !void {
        self.alive = true;
    }

    pub fn kill(self: Cell) !void {
        self.alive = false;
    }

    pub fn is_alive(self: Cell) bool {
        return self.alive;
    }

    pub fn set_coordinates(self: Cell, x: i32, y: i32) !void {
        self.x = x;
        self.y = y;
    }

    pub fn get_coordinates(self: Cell) struct { x: i32, y: i32 } {
        return .{ .x = self.x, .y = self.y };
    }
};
