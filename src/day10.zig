const std = @import("std");
const mvzr = @import("mvzr");

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
    while (it.next()) |line| {
        if (line.len == 0) continue;
        const puzzle = try read_puzzle(line, allocator);
        defer puzzle.deinit(allocator);
        sol_pt1 += try puzzle.solve_pt1(allocator);
    }
    std.debug.print("Part 1: {d}\n", .{sol_pt1});
}
