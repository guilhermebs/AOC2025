const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

pub fn main() !void {
    const input_fn = "inputs/day04.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var to_remove = std.array_list.Managed(usize).init(allocator);
    defer to_remove.deinit();
    try removable(content, &to_remove);
    const sol_pt1 = to_remove.items.len;
    var sol_pt2 = sol_pt1;
    while (to_remove.items.len > 0) {
        for (to_remove.items) |i| {
            content[i] = 'x';
        }
        try removable(content, &to_remove);
        sol_pt2 += to_remove.items.len;
    }

    std.debug.print("Part 1: {d}\n", .{sol_pt1});
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}

fn removable(content: []const u8, removed: *std.array_list.Managed(usize)) !void {
    removed.clearRetainingCapacity();
    const ncols = std.mem.indexOf(u8, content, "\n").? + 1;
    const nrows = content.len / ncols;

    for (0..content.len) |i| {
        if (content[i] == '@') {
            const row = @divTrunc(i, ncols);
            const col = @mod(i, ncols);
            var adjacent: i32 = -1;
            const x_start: usize = if (col == 0) 0 else col - 1;
            const x_end: usize = @min(col + 1, ncols - 1);
            const y_start: usize = if (row == 0) 0 else row - 1;
            const y_end: usize = @min(row + 1, nrows - 1);
            for (x_start..x_end + 1) |x| {
                for (y_start..y_end + 1) |y| {
                    adjacent += @intFromBool(content[x + y * ncols] == '@');
                }
            }
            if (adjacent < 4) {
                try removed.append(i);
            }
        }
    }
}
