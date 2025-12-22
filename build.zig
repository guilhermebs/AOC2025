const std = @import("std");

const Solution = struct { day: []const u8, file: []const u8 };

pub fn build(b: *std.Build) !void {
    const solutions = [_]Solution{
        .{ .day = "hello", .file = "src/hello.zig" },
        .{ .day = "day01", .file = "src/day01.zig" },
        .{ .day = "day02", .file = "src/day02.zig" },
        .{ .day = "day10", .file = "src/day10.zig" },
    };
    const mvzr = b.dependency("mvzr", .{});
    for (solutions) |sol| {
        const exe = b.addExecutable(.{
            .name = sol.day,
            .root_module = b.createModule(.{
                .root_source_file = b.path(sol.file),
                .target = b.graph.host,
            }),
        });
        exe.root_module.addImport("mvzr", mvzr.module("mvzr"));
        exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/Cellar/highs/1.12.0/include/highs" });
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/Cellar/highs/1.12.0/lib" });
        exe.linkSystemLibrary("highs");

        b.installArtifact(exe);
        const run_exe = b.addRunArtifact(exe);
        const run_step = b.step(sol.day, "Run executable");
        run_step.dependOn(&run_exe.step);
    }
}
