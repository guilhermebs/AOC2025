const std = @import("std");

const Solution = struct { day: []const u8, file: []const u8 };

pub fn build(b: *std.Build) !void {
    const solutions = [_]Solution{ .{ .day = "hello", .file = "src/hello.zig" }, .{ .day = "day01", .file = "src/day01.zig" } };
    for (solutions) |sol| {
        const exe = b.addExecutable(.{
            .name = sol.day,
            .root_module = b.createModule(.{
                .root_source_file = b.path(sol.file),
                .target = b.graph.host,
            }),
        });
        b.installArtifact(exe);
        const run_exe = b.addRunArtifact(exe);
        const run_step = b.step(sol.day, "Run executable");
        run_step.dependOn(&run_exe.step);
    }
}
