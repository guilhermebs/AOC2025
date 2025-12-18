const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

pub fn main() !void {
    const input_fn = "inputs/day03.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var it = std.mem.splitScalar(u8, content, '\n');
    var sol_pt1: u64 = 0;
    var sol_pt2: u64 = 0;
    while (it.next()) |line| {
        if (line.len == 0) continue;
        sol_pt1 += try max_joltage(line, 2);
        sol_pt2 += try max_joltage(line, 12);
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}

fn max_joltage(line: []const u8, comptime num_elements: usize) !u64 {
    var buf: [num_elements]u8 = undefined;
    var pos: usize = 0;
    for (0..num_elements) |i| {
        buf[i], const shift = get_max_in_line(line[pos..(line.len - num_elements + i + 1)]);
        pos += shift + 1;
    }
    return try std.fmt.parseInt(u64, buf[0..num_elements], 10);
}

fn get_max_in_line(line: []const u8) struct { u8, usize } {
    var max_digit: u8 = 0;
    var max_digit_idx: usize = 0;

    for (0..line.len) |i| {
        if (line[i] > max_digit) {
            max_digit = line[i];
            max_digit_idx = i;
        }
    }
    return .{ max_digit, max_digit_idx };
}
