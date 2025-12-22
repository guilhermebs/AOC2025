const std = @import("std");
const MAX_U8: usize = 1 << 63;

const Node = struct {
    name: []const u8,
    outputs: []const []const u8,
};

pub fn main() !void {
    const input_fn = "inputs/day11.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);

    var graph = std.StringHashMap([]const []const u8).init(allocator);
    defer {
        var git = graph.iterator();
        while (git.next()) |entry| {
            allocator.free(entry.value_ptr.*);
        }
        graph.deinit();
    }
    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        var it_line = std.mem.splitScalar(u8, line, ' ');
        const node_name = std.mem.trimEnd(u8, it_line.next().?, ":");
        var outputs: std.ArrayList([]const u8) = .empty;
        defer outputs.deinit(allocator);
        while (it_line.next()) |output| {
            try outputs.append(allocator, output);
        }
        try graph.putNoClobber(node_name, try outputs.toOwnedSlice(allocator));
    }

    var memory = std.StringHashMap(usize).init(allocator);
    defer memory.deinit();
    const sol_pt1 = try count_paths(graph, "you", "out", &memory);
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
    memory.clearAndFree();
    var memory_pt2 = std.AutoHashMap([5]u8, usize).init(allocator);
    defer memory_pt2.deinit();
    const sol_pt2 = try count_paths_pt2(graph, "svr", "out", false, false, &memory_pt2);
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}

fn count_paths(graph: std.StringHashMap([]const []const u8), source: []const u8, destination: []const u8, memory: *std.StringHashMap(usize)) !usize {
    if (memory.get(source)) |count| return count;
    if (std.mem.eql(u8, source, destination)) return 1;
    var result: usize = 0;
    if (graph.get(source)) |edges| {
        for (edges) |next| {
            result += try count_paths(graph, next, destination, memory);
        }
    }
    try memory.putNoClobber(source, result);
    return result;
}

fn count_paths_pt2(graph: std.StringHashMap([]const []const u8), source: []const u8, destination: []const u8, visit_dac: bool, visit_fft: bool, memory: *std.AutoHashMap([5]u8, usize)) !usize {
    const new_visit_dac = visit_dac or std.mem.eql(u8, source, "dac");
    const new_visit_fft = visit_fft or std.mem.eql(u8, source, "fft");
    var key = [_]u8{'_'} ** 5;
    std.mem.copyForwards(u8, &key, source);
    key[3] = @as(u8, @intFromBool(new_visit_dac)) + '0';
    key[4] = @as(u8, @intFromBool(new_visit_fft)) + '0';
    if (memory.get(key)) |count| return count;
    if (std.mem.eql(u8, source, destination)) return @intFromBool(visit_dac and visit_fft);
    var result: usize = 0;
    if (graph.get(source)) |edges| {
        for (edges) |next| {
            result += try count_paths_pt2(graph, next, destination, new_visit_dac, new_visit_fft, memory);
        }
    }
    try memory.putNoClobber(key, result);
    return result;
}
