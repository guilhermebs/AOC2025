const std = @import("std");
const mvzr = @import("mvzr");
const c = @cImport({
    @cInclude("interfaces/highs_c_api.h");
});

// C integer types
pub const c_double = f64;
pub const c_ptr = *anyopaque;
const NULL_CINT_PTR: *c_int = @ptrCast(@constCast(&[_]c_int{0}));
const NULL_CDOUBLE_PTR: *c_double = @ptrCast(@constCast(&[_]c_double{0}));

const MAX_U8: usize = 1 << 63;

const Puzzle = struct {
    goal: usize,
    buttons: []const usize,
    joltage_reqs: []const usize,

    fn deinit(self: @This(), alocator: std.mem.Allocator) void {
        alocator.free(self.buttons);
        alocator.free(self.joltage_reqs);
    }

    fn solve_pt1(self: @This(), allocator: std.mem.Allocator) !usize {
        const State = struct {
            lights: usize,
            nsteps: usize,
            fn prioriry(context: void, first: @This(), second: @This()) std.math.Order {
                _ = context;
                return std.math.order(first.nsteps, second.nsteps);
            }
        };
        var deque = std.PriorityDequeue(State, void, State.prioriry).init(allocator, {});
        defer deque.deinit();
        try deque.add(State{ .lights = 0, .nsteps = 0 });
        var seen: std.AutoArrayHashMapUnmanaged(usize, void) = .empty;
        defer seen.deinit(allocator);
        try seen.putNoClobber(allocator, 0, {});
        while (deque.removeMinOrNull()) |state| {
            if (state.lights == self.goal) {
                return state.nsteps;
            }
            for (self.buttons) |b| {
                const new_lights = b ^ state.lights;
                if (~seen.contains(new_lights)) {
                    try seen.putNoClobber(allocator, new_lights, {});
                    try deque.add(State{ .lights = new_lights, .nsteps = state.nsteps + 1 });
                }
            }
        }
        unreachable;
    }
    fn solve_pt2(self: @This(), allocator: std.mem.Allocator) !usize {
        const highs = c.Highs_create().?;
        defer _ = c.Highs_destroy(highs); // Ensure cleanup
        const inf = c.Highs_getInfinity(highs);
        const num_cols = self.buttons.len;
        const num_rows = self.joltage_reqs.len;
        for (0..num_cols) |i| {
            if (c.Highs_addCol(
                highs,
                1,
                0.0,
                inf,
                0,
                NULL_CINT_PTR,
                NULL_CDOUBLE_PTR,
            ) != c.kHighsStatusOk) {
                return error.FailedToAddCols;
            }
            if (c.Highs_changeColIntegrality(highs, @as(c_int, @intCast(i)), c.kHighsVarTypeInteger) != c.kHighsStatusOk) {
                return error.FailedToSetIntegrality;
            }
        }

        var indices: std.ArrayList(c_int) = .empty;
        defer indices.deinit(allocator);
        var values = [_]c_double{1.0} ** 32;
        var cur_idx: usize = 0;
        std.debug.print("Matrix:\n", .{});
        for (0..num_rows) |i| {
            var num_new_nz: c_int = 0;
            for (0..num_cols) |j| {
                if ((self.buttons[j] >> @as(u6, @intCast(i))) % 2 == 1) {
                    try indices.append(allocator, @as(c_int, @intCast(j)));
                    std.debug.print("{d}, ", .{j});
                    num_new_nz += 1;
                }
            }
            std.debug.print("\n", .{});
            if (c.Highs_addRow(highs, @floatFromInt(self.joltage_reqs[i]), @floatFromInt(self.joltage_reqs[i]), num_new_nz, &indices.items[cur_idx], &values[0]) != c.kHighsStatusOk) {
                return error.FailedToAddCols;
            }
            cur_idx += @intCast(num_new_nz);
        }
        if (c.Highs_run(highs) != c.kHighsStatusOk) {
            return error.HighsRunFailed;
        }

        const objective_value: c_double = c.Highs_getObjectiveValue(highs);
        return @intFromFloat(objective_value);
    }
};

fn read_puzzle(line: []const u8, allocator: std.mem.Allocator) !Puzzle {
    const goal_regex: mvzr.Regex = mvzr.compile("([\\.#]+)").?;
    const button_regex: mvzr.Regex = mvzr.compile("([0-9,]+)").?;
    const match = goal_regex.match(line).?;
    var goal: usize = 0;
    for (0..match.slice.len) |i| goal |= (@as(usize, @intFromBool(match.slice[i] == '#')) << @as(u6, @intCast(i)));
    const n_buttons = std.mem.count(u8, line, "(");
    var iter = button_regex.iterator(line);
    var buttons = try allocator.alloc(usize, n_buttons);
    errdefer allocator.free(buttons);
    @memset(buttons, 0);
    for (0..n_buttons) |ib| {
        const m = iter.next().?;
        var iter_digits = std.mem.splitScalar(u8, m.slice, ',');
        while (iter_digits.next()) |digits_str| {
            const d = try std.fmt.parseInt(u6, digits_str, 10);
            buttons[ib] ^= @as(usize, 1) << d;
        }
    }
    const m = iter.next().?;
    var digits: std.ArrayList(usize) = .empty;
    defer digits.deinit(allocator);
    var iter_digits = std.mem.splitScalar(u8, m.slice, ',');
    while (iter_digits.next()) |digits_str| {
        try digits.append(allocator, try std.fmt.parseInt(usize, digits_str, 10));
    }

    return Puzzle{ .goal = goal, .buttons = buttons, .joltage_reqs = try digits.toOwnedSlice(allocator) };
}

pub fn main() !void {
    const input_fn = "inputs/day10.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const content = try std.fs.cwd().readFileAlloc(allocator, input_fn, MAX_U8);
    defer allocator.free(content);
    var it = std.mem.splitScalar(u8, content, '\n');
    var sol_pt1: usize = 0;
    var sol_pt2: usize = 0;
    while (it.next()) |line| {
        if (line.len == 0) continue;
        const puzzle = try read_puzzle(line, allocator);
        defer puzzle.deinit(allocator);
        sol_pt1 += try puzzle.solve_pt1(allocator);
        sol_pt2 += try puzzle.solve_pt2(allocator);
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
    std.debug.print("Part 2: {d}\n", .{sol_pt2});
}
