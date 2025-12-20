const std = @import("std");
const expect = std.testing.expect;

const MAX_U8: usize = 1 << 63;

const coordT = i64;
const DEBUG = false;
const Point = struct { col: coordT, row: coordT };

pub fn main() !void {
    const input_fn = "inputs/day09.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);

    var red_tiles: std.ArrayList(Point) = .empty;
    defer red_tiles.deinit(allocator);

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        if (line.len == 0) break;
        var it_line = std.mem.splitScalar(u8, line, ',');
        try red_tiles.append(allocator, //
            Point{
                .col = try std.fmt.parseInt(coordT, it_line.next().?, 10), //
                .row = try std.fmt.parseInt(coordT, it_line.next().?, 10), //
            });
    }
    var sol_pt1: usize = 0;
    for (red_tiles.items) |t1| {
        for (red_tiles.items) |t2| {
            const side1 = @abs(t1.row - t2.row) + 1;
            const side2 = @abs(t1.col - t2.col) + 1;
            const area = side1 * side2;
            sol_pt1 = @max(sol_pt1, area);
        }
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
    var sol_pt2: usize = 0;
    for (red_tiles.items) |t1| {
        for (red_tiles.items) |t2| {
            if (DEBUG) {
                std.debug.print("t1: ({d}, {d})\n", .{ t1.col, t1.row });
                std.debug.print("t2: ({d}, {d})\n", .{ t2.col, t2.row });
            }
            const edges = [_]Point{ t1, .{ .row = t1.row, .col = t2.col }, t2, .{ .row = t2.row, .col = t1.col } };
            var is_inside: bool = true;
            for (0..4) |i| {
                const e1 = edges[i];
                const e2 = edges[(i + 1) % 4];
                if (!point_in_polygon(red_tiles.items, e1)) {
                    is_inside = false;
                    if (DEBUG) std.debug.print("edge ({d}, {d}) outside!\n", .{ e1.col, e1.row });
                    break;
                } else if (line_polygon_intersect(red_tiles.items, &[_]Point{ e1, e2 })) {
                    if (DEBUG) std.debug.print("side ({d}, {d}), ({d}, {d}) outside!\n", .{ e1.col, e1.row, e2.col, e2.row });
                    is_inside = false;
                    break;
                }
            }
            if (DEBUG) std.debug.print("is_inside: {b}\n", .{@intFromBool(is_inside)});
            if (is_inside) {
                const side1 = @abs(t1.row - t2.row) + 1;
                const side2 = @abs(t1.col - t2.col) + 1;
                const area = side1 * side2;
                sol_pt2 = @max(sol_pt2, area);
            }
        }
    }
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}

fn point_in_polygon(polygon: []const Point, test_point: Point) bool {
    var count_intersections: usize = 0;
    if (DEBUG) std.debug.print("edge: ({d}, {d})\n", .{ test_point.col, test_point.row });
    for (0..polygon.len) |i| {
        const p1 = polygon[i];
        if (p1.row == test_point.row and p1.col == test_point.col) return true;
        const p2 = polygon[(i + 1) % polygon.len];
        if (DEBUG) std.debug.print("line: ({d}, {d}), ({d}, {d})\n", .{ p1.col, p1.row, p2.col, p2.row });
        if (p1.row == p2.row) {
            const col_min = @min(p1.col, p2.col);
            const col_max = @max(p1.col, p2.col);
            if (test_point.row > p1.row) {
                count_intersections += @intFromBool((col_min <= test_point.col and test_point.col < col_max));
            } else if (test_point.row == p1.row and col_min <= test_point.col and test_point.col <= col_max) {
                return true;
            }
        }
        if (p1.col == p2.col and test_point.col == p1.col) {
            const row_min = @min(p1.row, p2.row);
            const row_max = @max(p1.row, p2.row);
            if (row_min <= test_point.row and test_point.row <= row_max) {
                return true;
            }
        }
        if (DEBUG) std.debug.print("intersections: {d}\n", .{count_intersections});
    }
    return count_intersections % 2 == 1;
}

fn line_polygon_intersect(polygon: []const Point, line: []const Point) bool {
    if (line[0].col == line[1].col) {
        for (0..polygon.len) |i| {
            const p1 = polygon[i];
            const p2 = polygon[(i + 1) % polygon.len];
            if (p1.row == p2.row) {
                if (perp_line_intersect(line, &[_]Point{ p1, p2 })) {
                    return true;
                }
            } else if (line[0].col == p1.col) {
                const side_min = @min(p1.row, p2.row);
                const side_max = @max(p1.row, p2.row);
                const line_min = @min(line[0].row, line[1].row);
                const line_max = @max(line[0].row, line[1].row);
                if (line_min < side_min and line_max <= side_max and ~point_in_polygon(polygon, Point{ .row = side_min - 1, .col = line[0].col })) {
                    return true;
                } else if (line_max > side_max and line_min >= side_min and ~point_in_polygon(polygon, Point{ .row = side_max + 1, .col = line[0].col })) {
                    return true;
                }
            }
        }
    }
    if (line[0].row == line[1].row) {
        for (0..polygon.len) |i| {
            const p1 = polygon[i];
            const p2 = polygon[(i + 1) % polygon.len];
            if (p1.col == p2.col) {
                if (perp_line_intersect(&[_]Point{ p1, p2 }, line)) {
                    return true;
                }
            } else if (line[0].row == p1.row) {
                const side_min = @min(p1.col, p2.col);
                const side_max = @max(p1.col, p2.col);
                const line_min = @min(line[0].col, line[1].col);
                const line_max = @max(line[0].col, line[1].col);
                if (line_min < side_min and ~point_in_polygon(polygon, Point{ .row = line[0].row, .col = side_min - 1 })) {
                    return true;
                } else if (line_max > side_max and ~point_in_polygon(polygon, Point{ .row = line[0].row, .col = side_max + 1 })) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn perp_line_intersect(v: []const Point, h: []const Point) bool {
    //try expect(v[0].col == v[1].col);
    //try expect(h[0].row == h[1].row);
    //std.debug.print("v: ({d}, {d}), ({d}, {d})\n", .{ v[0].row, v[0].col, v[1].row, v[1].col });
    //std.debug.print("h: ({d}, {d}), ({d}, {d})\n", .{ h[0].row, h[0].col, h[1].row, h[1].col });
    const row_min = @min(v[0].row, v[1].row);
    const row_max = @max(v[0].row, v[1].row);
    const col_min = @min(h[0].col, h[1].col);
    const col_max = @max(h[0].col, h[1].col);
    if (row_min < h[0].row and h[0].row < row_max and col_min < v[0].col and v[0].col < col_max) {
        return true;
    }
    return false;
}

test "point_in_polygon" {
    const polygon = [_]Point{ .{ .row = 1, .col = 1 }, .{ .row = 1, .col = -1 }, .{ .row = -1, .col = -1 }, .{ .row = -1, .col = 1 } };
    try expect(~point_in_polygon(&polygon, Point{ .row = 2, .col = 0 }));
    try expect(~point_in_polygon(&polygon, Point{ .row = 0, .col = 2 }));
    try expect(point_in_polygon(&polygon, Point{ .row = 0, .col = 0 }));
    try expect(point_in_polygon(&polygon, Point{ .row = 1, .col = 1 }));
    try expect(~point_in_polygon(&polygon, Point{ .row = -2, .col = 0 }));
    try expect(point_in_polygon(&polygon, Point{ .row = -1, .col = 0 }));
}

test "point_in_polygon_nonconvex" {
    const polygon = [_]Point{
        .{ .row = 2, .col = 2 }, //
        .{ .row = 2, .col = 1 }, //
        .{ .row = 1, .col = 1 }, //
        .{ .row = 1, .col = -1 }, //
        .{ .row = 2, .col = -1 }, //
        .{ .row = 2, .col = -2 }, //
        .{ .row = -2, .col = -2 }, //
        .{ .row = -2, .col = 2 }, //
    };
    try expect(~point_in_polygon(&polygon, Point{ .row = 3, .col = 0 }));
    try expect(~point_in_polygon(&polygon, Point{ .row = 0, .col = 3 }));
    try expect(point_in_polygon(&polygon, Point{ .row = 0, .col = 0 }));
    try expect(point_in_polygon(&polygon, Point{ .row = 1, .col = 1 }));
    try expect(~point_in_polygon(&polygon, Point{ .row = 2, .col = 0 }));
    try expect(point_in_polygon(&polygon, Point{ .row = 1, .col = 1 }));
    try expect(point_in_polygon(&polygon, Point{ .row = -1, .col = 0 }));
}

test "line_in_polygon" {
    const polygon = [_]Point{ .{ .row = 1, .col = 1 }, .{ .row = 1, .col = -1 }, .{ .row = -1, .col = -1 }, .{ .row = -1, .col = 1 } };
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 2, .col = 0 }, .{ .row = 3, .col = 0 } }));
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 0, .col = 2 }, .{ .row = 0, .col = 3 } }));
    try expect(line_polygon_intersect(&polygon, &[_]Point{ .{ .row = -2, .col = 0 }, .{ .row = 0, .col = 0 } }));
    try expect(line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 0, .col = 0 }, .{ .row = 0, .col = 2 } }));
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 1, .col = 1 }, .{ .row = -1, .col = 1 } }));
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 1, .col = 1 }, .{ .row = -1, .col = 0 } }));
}

test "line_in_polygon_nonconvex" {
    const polygon = [_]Point{
        .{ .row = 2, .col = 2 }, //
        .{ .row = 2, .col = 1 }, //
        .{ .row = 1, .col = 1 }, //
        .{ .row = 1, .col = -1 }, //
        .{ .row = 2, .col = -1 }, //
        .{ .row = 2, .col = -2 }, //
        .{ .row = -2, .col = -2 }, //
        .{ .row = -2, .col = 2 }, //
    };
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 3, .col = 0 }, .{ .row = 4, .col = 0 } }));
    try expect(~line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 0, .col = 3 }, .{ .row = 0, .col = 4 } }));
    try expect(line_polygon_intersect(&polygon, &[_]Point{ .{ .row = -3, .col = 0 }, .{ .row = 0, .col = 0 } }));
    try expect(line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 2, .col = 0 }, .{ .row = 0, .col = 0 } }));
    try expect(line_polygon_intersect(&polygon, &[_]Point{ .{ .row = 2, .col = 2 }, .{ .row = 2, .col = -2 } }));
}
