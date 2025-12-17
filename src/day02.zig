const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

pub fn main() !void {
    const input_fn = "inputs/day02.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var it = std.mem.splitScalar(u8, content, ',');
    var sol_pt1: u64 = 0;
    var sol_pt2: u64 = 0;
    var buf: [256]u8 = undefined;
    while (it.next()) |range| {
        const dash = std.mem.indexOf(u8, range, "-");
        if (dash) |idx| {
            const range_start = try std.fmt.parseInt(u64, range[0..idx], 10);
            const range_end = try std.fmt.parseInt(u64, range[idx + 1 .. range.len], 10);
            for (range_start..(range_end + 1)) |v| {
                const str = try std.fmt.bufPrint(&buf, "{d}", .{v});
                if (str.len == 1) continue;
                if (is_repeated(str, 2)) {
                    sol_pt1 += v;
                }
                for (2..(str.len + 1)) |num_splits| {
                    if (is_repeated(str, num_splits)) {
                        sol_pt2 += v;
                        break;
                    }
                }
            }
        }
    }
    std.debug.print("Part 1 solution: {d}\n", .{sol_pt1});
    std.debug.print("Part 2 solution: {d}\n", .{sol_pt2});
}

fn is_repeated(string: []const u8, num_splits: usize) bool {
    if (string.len % num_splits != 0) return false;
    const seq_len = string.len / num_splits;
    const head_seq = string[0..seq_len];
    for (1..num_splits) |i| {
        if (~std.mem.eql(u8, head_seq, string[i * seq_len .. ((i + 1) * seq_len)])) {
            return false;
        }
    }
    return true;
}

test "is_repeated" {
    try expect(is_repeated("1212", 2));
    try expect(is_repeated("121212", 3));
    try expect(~is_repeated("11112", 3));
    try expect(~is_repeated("111122", 3));
    try expect(is_repeated("111", 3));
}
