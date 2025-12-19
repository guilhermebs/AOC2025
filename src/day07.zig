const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

pub fn main() !void {
    const input_fn = "inputs/day07.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    const num_cols = std.mem.indexOf(u8, content, "\n").? + 1;
    const num_rows = std.mem.count(u8, content, "\n");

    var line_above = content[0..num_cols];
    var sol_pt1: usize = 0;
    for (1..num_rows) |row| {
        for (0..num_cols) |col| {
            if (line_above[col] == 'S') {
                switch (content[row * num_cols + col]) {
                    '.' => {},
                    '^' => {
                        line_above[col - 1] = 'S';
                        line_above[col] = '.';
                        line_above[col + 1] = 'S';
                        sol_pt1 += 1;
                    },
                    else => std.debug.print("Invalid char! \n", .{}),
                }
            }
        }
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
}
