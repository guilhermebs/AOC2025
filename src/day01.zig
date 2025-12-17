const std = @import("std");
const MAX_U8: usize = 1 << 63;
pub fn main() !void {
    const input_fn = "inputs/day01.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const content = try std.fs.cwd().readFileAlloc(alloc, input_fn, MAX_U8);
    defer alloc.free(content);
    var it = std.mem.splitScalar(u8, content, '\n');
    const size: i32 = 100;
    var pos: i32 = 50;
    var count_pt1: u32 = 0;
    var count_pt2: u32 = 0;
    while (it.next()) |line| {
        if (line.len == 0) {
            break;
        }
        const clicks = try std.fmt.parseInt(i32, line[1..line.len], 10);
        switch (line[0]) {
            'R' => pos += clicks,
            'L' => pos -= clicks,
            else => return error.NotFound,
        }
        count_pt2 += @abs(@divTrunc(pos, size));
        count_pt2 += @intFromBool(pos == 0);
        count_pt2 += @intFromBool((pos < 0) and (pos > -clicks));
        pos = @mod(pos, size);
        count_pt1 += @intFromBool(pos == 0);
    }

    std.debug.print("pt1: {d}, pt2: {d}\n", .{ count_pt1, count_pt2 });
}
