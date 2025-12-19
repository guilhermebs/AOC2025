const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

pub fn main() !void {
    const input_fn = "inputs/day06.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var it_lines = std.mem.splitScalar(u8, content, '\n');

    var inputs: std.ArrayList(u64) = .empty;
    defer inputs.deinit(allocator);
    var ops: std.ArrayList(u8) = .empty;
    defer ops.deinit(allocator);
    var linenr: usize = 0;
    const num_operands = std.mem.count(u8, content, "\n") - 1;
    while (it_lines.next()) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        if (linenr < num_operands) {
            while (it.next()) |num| {
                if (std.fmt.parseInt(u64, num, 10)) |num_u64| {
                    try inputs.append(allocator, num_u64);
                } else |_| {
                    continue;
                }
            }
        }
        if (linenr == num_operands) {
            for (line) |char| {
                if (char != ' ') {
                    try ops.append(allocator, char);
                }
            }
        }
        linenr += 1;
    }
    var sol_pt1: u64 = 0;
    const num_operations = ops.items.len;
    for (0..num_operations) |i| {
        var results = inputs.items[i];
        for (1..num_operands) |j| {
            switch (ops.items[i]) {
                '+' => results += inputs.items[i + num_operations * j],
                '*' => results *= inputs.items[i + num_operations * j],
                else => {},
            }
        }
        sol_pt1 += results;
    }
    std.debug.print("{d}\n", .{sol_pt1});

    inputs.clearRetainingCapacity();
    var input_size: std.ArrayList(usize) = .empty;
    defer input_size.deinit(allocator);
    try input_size.ensureTotalCapacity(allocator, ops.items.len);
    const line_size = std.mem.indexOf(u8, content, "\n").? + 1;
    var num_ops: usize = 0;
    for (0..line_size) |i| {
        var value: u64 = 0;
        for (0..num_operands) |j| {
            const c = content[j * line_size + i];
            //std.debug.print("{c}\n", .{c});
            if (c != ' ' and c != '\n') {
                const cint = c - '0';
                value = value * 10 + cint;
            }
        }
        if (value > 0) {
            //std.debug.print("{d}\n", .{value});
            try inputs.append(allocator, value);
            num_ops += 1;
        } else if (num_ops > 0) {
            try input_size.append(allocator, num_ops);
            //std.debug.print("{d}\n", .{num_ops});
            num_ops = 0;
        }
    }
    var sol_pt2: u64 = 0;
    var used_inputs: usize = 0;
    for (0..num_operations) |i| {
        var results = inputs.items[used_inputs];
        for (1..input_size.items[i]) |j| {
            switch (ops.items[i]) {
                '+' => results += inputs.items[used_inputs + j],
                '*' => results *= inputs.items[used_inputs + j],
                else => {},
            }
        }
        used_inputs += input_size.items[i];
        sol_pt2 += results;
    }
    std.debug.print("{d}\n", .{sol_pt2});
}
