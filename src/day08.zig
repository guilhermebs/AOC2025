const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

const coordT = i64;

const JunctionBox = struct {
    x: coordT,
    y: coordT,
    z: coordT,
    pub fn distance(self: JunctionBox, other: JunctionBox) coordT {
        return std.math.pow(coordT, (self.x - other.x), 2) + std.math.pow(coordT, (self.y - other.y), 2) + std.math.pow(coordT, (self.z - other.z), 2);
    }
};

pub fn main() !void {
    const input_fn = "inputs/day08.txt";
    const num_connections = 1000;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);

    const num = std.mem.count(u8, content, "\n");
    var boxes = try allocator.alloc(JunctionBox, num);
    defer allocator.free(boxes);

    var it = std.mem.splitScalar(u8, content, '\n');
    for (0..num) |i| {
        const line = it.next().?;
        var line_split = std.mem.splitScalar(u8, line, ',');
        boxes[i] = JunctionBox{
            .x = try std.fmt.parseInt(coordT, line_split.next().?, 10),
            .y = try std.fmt.parseInt(coordT, line_split.next().?, 10),
            .z = try std.fmt.parseInt(coordT, line_split.next().?, 10),
        };
    }
    const distances = try allocator.alloc(coordT, num * num);
    defer allocator.free(distances);
    for (0..num) |i| {
        for (i..num) |j| {
            if (i == j) {
                distances[i * num + j] = std.math.maxInt(coordT);
            } else {
                const dist = boxes[i].distance(boxes[j]);
                distances[i * num + j] = dist;
                distances[j * num + i] = dist;
            }
        }
    }
    var circuits: std.ArrayList(std.AutoHashMap(usize, void)) = .empty;
    defer {
        for (circuits.items) |*map| {
            map.deinit();
        }
        circuits.deinit(allocator);
    }
    var smallest_dist = try allocator.alloc(usize, distances.len);
    defer allocator.free(smallest_dist);
    for (0..distances.len) |i| {
        smallest_dist[i] = i;
    }
    sort_indices(coordT, distances, Comp.Lt, smallest_dist);
    var idx_dist: usize = 0;
    var count_connections: usize = 0;
    var circuit_sizes: std.ArrayList(usize) = .empty;
    defer circuit_sizes.deinit(allocator);

    while (true) {
        const idx = smallest_dist[idx_dist];
        const box_a = idx / num;
        const box_b = idx % num;
        std.debug.print("Box pair: {d}:({d}, {d}, {d}) {d}:({d}, {d}, {d})\n", .{ box_a, boxes[box_a].x, boxes[box_a].y, boxes[box_a].z, box_b, boxes[box_b].x, boxes[box_b].y, boxes[box_b].z });
        //std.debug.print("{d}, {d}\n", .{ box_a, box_b });
        var maybe_boxa_circuit: ?usize = null;
        var maybe_boxb_circuit: ?usize = null;
        for (0..circuits.items.len) |ci| {
            if (circuits.items[ci].contains(box_a)) {
                maybe_boxa_circuit = ci;
            }
            if (circuits.items[ci].contains(box_b)) {
                maybe_boxb_circuit = ci;
            }
        }
        if (maybe_boxa_circuit) |boxa_circuit| {
            if (maybe_boxb_circuit) |boxb_circuit| {
                if (boxa_circuit != boxb_circuit) {
                    var viter = circuits.items[boxb_circuit].keyIterator();
                    while (viter.next()) |box| {
                        try circuits.items[boxa_circuit].putNoClobber(box.*, {});
                    }
                    circuits.items[boxb_circuit].clearAndFree();
                }
            } else {
                try circuits.items[boxa_circuit].putNoClobber(box_b, {});
            }
        } else if (maybe_boxb_circuit) |boxb_circuit| {
            try circuits.items[boxb_circuit].putNoClobber(box_a, {});
        } else {
            var hmap = std.AutoHashMap(usize, void).init(allocator);
            try hmap.putNoClobber(box_a, {});
            try hmap.putNoClobber(box_b, {});
            try circuits.append(allocator, hmap);
        }
        count_connections += 1;
        idx_dist += 2;
        //std.debug.print("{d}\n", .{count_connections});
        //for (circuits.items) |circuit| {
        //    print_set(circuit);
        //}
        circuit_sizes.clearRetainingCapacity();
        for (circuits.items) |c| {
            try circuit_sizes.append(allocator, c.count());
        }
        std.mem.sort(usize, circuit_sizes.items, {}, comptime std.sort.desc(usize));
        if (count_connections == num_connections) {
            const sol_pt1 = circuit_sizes.items[0] * circuit_sizes.items[1] * circuit_sizes.items[2];
            std.debug.print("Part 1: {d}\n", .{sol_pt1});
        }
        if (circuit_sizes.items.len > 1 and circuit_sizes.items[0] == boxes.len) {
            const sol_pt2 = boxes[box_a].x * boxes[box_b].x;
            std.debug.print("Part 2: {d}\n", .{sol_pt2});
            break;
        }
    }
}

const Comp = enum { Gt, Lt };

fn sort_indices(comptime T: type, values: []const T, comptime comp: Comp, sorted_indices: []usize) void {
    const Context = struct {
        values: []const T,
        fn compFunc(self: @This(), i: usize, j: usize) bool {
            switch (comp) {
                .Gt => return self.values[i] > self.values[j],
                .Lt => return self.values[i] < self.values[j],
            }
        }
    };
    std.mem.sort(usize, sorted_indices, Context{ .values = values }, Context.compFunc);
}

fn print_set(set: std.AutoHashMap(usize, void)) void {
    var iter = set.keyIterator();
    std.debug.print("(", .{});
    while (iter.next()) |k| {
        std.debug.print("{d}, ", .{k.*});
    }
    std.debug.print(")\n", .{});
}

test "sort_indices" {
    const values: [4]u32 = .{ 10, 40, 30, 50 };
    const expected_gt: [4]usize = .{ 3, 1, 2, 0 };
    var sut: [4]usize = .{ 0, 1, 2, 3 };
    sort_indices(u32, &values, Comp.Gt, &sut);
    try expect(std.mem.eql(usize, &sut, &expected_gt));
    const expected_lt: [4]usize = .{ 0, 2, 1, 3 };
    sort_indices(u32, &values, Comp.Lt, &sut);
    try expect(std.mem.eql(usize, &sut, &expected_lt));
}
