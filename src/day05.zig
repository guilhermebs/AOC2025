const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

const Range = struct {
    start: u64,
    end: u64,
    pub fn contains(self: Range, value: u64) bool {
        return (self.start <= value) and (value <= self.end);
    }
    pub fn merge(self: Range, other: Range) struct { Range, ?Range } {
        if (self.contains(other.start)) {
            return .{ Range{ .start = self.start, .end = @max(self.end, other.end) }, null };
        }
        if (self.contains(other.end)) {
            return .{ Range{ .start = @min(self.start, other.start), .end = self.end }, null };
        }
        return .{ self, other };
    }
};

pub fn main() !void {
    const input_fn = "inputs/day05.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var it = std.mem.splitScalar(u8, content, '\n');

    var fresh_ranges: std.ArrayList(Range) = .empty;
    defer fresh_ranges.deinit(allocator);

    var mode: u8 = 0;
    var sol_pt1: u64 = 0;
    while (it.next()) |line| {
        if (line.len == 0 and mode == 0) mode = 1;
        if (line.len == 0 and mode == 1) continue;
        if (mode == 0) {
            const dash = std.mem.indexOf(u8, line, "-").?;
            const start = try std.fmt.parseInt(u64, line[0..dash], 10);
            const end = try std.fmt.parseInt(u64, line[dash + 1 .. line.len], 10);
            try fresh_ranges.append(allocator, Range{ .start = start, .end = end });
        }
        if (mode == 1) {
            const ingredient = try std.fmt.parseInt(u64, line, 10);
            for (fresh_ranges.items) |range| {
                if (range.contains(ingredient)) {
                    sol_pt1 += 1;
                    break;
                }
            }
        }
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});

    var simplified_ranges: std.ArrayList(Range) = .empty;
    defer simplified_ranges.deinit(allocator);
    try simplified_ranges.appendSlice(allocator, fresh_ranges.items);
    while (check_overlaps(simplified_ranges.items)) {
        fresh_ranges.clearRetainingCapacity();
        try fresh_ranges.appendSliceBounded(simplified_ranges.items);
        simplified_ranges.clearRetainingCapacity();
        var range1 = fresh_ranges.items[0];
        for (fresh_ranges.items[1..]) |range2| {
            range1, const r2 = range1.merge(range2);
            if (r2) |r2_notnull| {
                try simplified_ranges.appendBounded(r2_notnull);
            }
        }
        try simplified_ranges.appendBounded(range1);
    }
    var sol_pt2: usize = 0;
    for (simplified_ranges.items) |range| {
        sol_pt2 += range.end - range.start + 1;
    }
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}

fn check_overlaps(ranges: []const Range) bool {
    for (0..ranges.len) |i| {
        for (i + 1..ranges.len) |j| {
            if (ranges[i].contains(ranges[j].start)) return true;
            if (ranges[i].contains(ranges[j].end)) return true;
            if (ranges[j].contains(ranges[i].start)) return true;
            if (ranges[j].contains(ranges[i].end)) return true;
        }
    }
    return false;
}
