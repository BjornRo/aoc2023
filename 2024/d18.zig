const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn as(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
};

const State = struct {
    steps: u32,
    position: Point,
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: Point) u32 {
        return @bitCast([2]CT{ key.row, key.col });
    }
    pub fn eql(_: @This(), a: Point, b: Point, _: usize) bool {
        return a.eq(b);
    }
};
const Set = std.ArrayHashMap(Point, void, HashCtx, true);

fn inBounds(point: Point, dimension: CT) bool {
    return (0 <= point.row and point.row < dimension and
        0 <= point.col and point.col < dimension);
}

fn part1(allocator: Allocator, map: []const []const bool, dimension: CT, end_pos: Point) !u32 {
    var visited = try myf.initValueMatrix(allocator, @intCast(dimension), @intCast(dimension), false);
    defer myf.freeMatrix(allocator, visited);

    var queue = try Deque(State).initCapacity(allocator, @intCast(dimension * dimension));
    defer queue.deinit();
    try queue.pushBack(.{ .steps = 0, .position = Point.init(0, 0) });

    var min_steps = ~@as(u32, 0);
    while (queue.len() != 0) {
        const state = queue.popFront().?;

        if (state.steps >= min_steps) continue;
        if (state.position.eq(end_pos)) {
            if (state.steps < min_steps) min_steps = state.steps;
            continue;
        }

        const row, const col = state.position.as();
        if (visited[row][col]) continue;
        visited[row][col] = true;

        for (myf.getNextPositions(@as(i16, @intCast(row)), @as(i16, @intCast(col)))) |next_position_coords| {
            const next_position = Point.init(next_position_coords[0], next_position_coords[1]);
            if (!inBounds(next_position, dimension)) continue;
            const nrow, const ncol = next_position.as();
            if (map[nrow][ncol]) continue;
            try queue.pushBack(.{ .steps = state.steps + 1, .position = next_position });
        }
    }
    return min_steps;
}

fn part2(allocator: Allocator, map: []const []const bool, dimension: CT, end_pos: Point) !bool {
    var visited = try myf.initValueMatrix(allocator, @intCast(dimension), @intCast(dimension), false);
    defer myf.freeMatrix(allocator, visited);

    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();
    try stack.append(.{ .steps = 0, .position = Point.init(0, 0) });

    while (stack.items.len != 0) {
        const state = stack.pop();

        if (state.position.eq(end_pos)) return true;
        const row, const col = state.position.as();
        if (visited[row][col]) continue;
        visited[row][col] = true;

        for (myf.getNextPositions(@as(i16, @intCast(row)), @as(i16, @intCast(col)))) |next_position_coords| {
            const next_position = Point.init(next_position_coords[0], next_position_coords[1]);
            if (!inBounds(next_position, dimension)) continue;
            const nrow, const ncol = next_position.as();
            if (map[nrow][ncol]) continue;
            try stack.append(.{ .steps = state.steps + 1, .position = next_position });
        }
    }
    return false;
}

pub fn printGrid(allocator: Allocator, dimension: u8, positions: []const Point, point: ?Point) void {
    const stdout = std.io.getStdOut().writer();
    var matrix = myf.initValueMatrix(allocator, dimension, dimension, @as(u8, '.')) catch unreachable;
    defer myf.freeMatrix(allocator, matrix);

    for (positions) |pos| matrix[@intCast(pos.row)][@intCast(pos.col)] = '#';
    if (point) |p| matrix[@intCast(p.row)][@intCast(p.col)] = 'O';
    for (matrix) |arr| stdout.print("{s}\n", .{arr}) catch unreachable;
    stdout.print("\n", .{}) catch unreachable;
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [300_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const dimension: CT = 70 + 1;
    var lower: usize = 1024;

    var map = try myf.initValueMatrix(allocator, @intCast(dimension), @intCast(dimension), false);
    var list = std.ArrayList(Point).init(allocator);
    try list.ensureTotalCapacity(@intCast(dimension * dimension));
    defer list.deinit();

    var p1_result: u32 = 0;
    var p2_result = Point.init(-1, -1);

    var size: usize = 0;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |raw_point| {
        var point_iter = std.mem.tokenizeScalar(u8, raw_point, ',');
        const left = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        const right = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        list.appendAssumeCapacity(Point.init(right, left));
        size += 1;
        if (size <= lower) {
            map[@intCast(right)][@intCast(left)] = true;
            if (size == lower) {
                p1_result = try part1(allocator, map, dimension, Point.init(dimension - 1, dimension - 1));
            }
        }
    }
    myf.freeMatrix(allocator, map);

    lower += 1;
    var mid_point: usize = undefined;
    while (true) {
        mid_point = lower + (size - lower) / 2;

        map = try myf.initValueMatrix(allocator, @intCast(dimension), @intCast(dimension), false);
        defer myf.freeMatrix(allocator, map);

        for (list.items[0..mid_point]) |key| {
            const krow, const kcol = key.as();
            map[krow][kcol] = true;
        }
        const last_point = list.items[mid_point - 1];

        var neighbors: u8 = 0;
        const row, const col = last_point.toArr();
        for (myf.getNextPositions(row, col)) |neighbor| {
            const new_point = Point.init(neighbor[0], neighbor[1]);
            const nrow, const ncol = new_point.toArr();
            if (!inBounds(new_point, dimension) or map[@intCast(nrow)][@intCast(ncol)]) neighbors += 1;
            if (neighbors == 2) break;
        }
        if (neighbors == 2) {
            if (!try part2(allocator, map, dimension, Point.init(dimension - 1, dimension - 1))) {
                if (lower == mid_point) {
                    p2_result = last_point;
                    break;
                }
                size = mid_point + (size - mid_point) / 2;
                continue;
            }
        }
        lower = mid_point + 1;
    }
    try writer.print("Part 1: {d}\nPart 2: {d},{d}\n", .{
        p1_result,
        p2_result.col,
        p2_result.row,
    });
}

test "p1" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d18t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const dimension: CT = 6 + 1;
    const max_bytes = 12;

    var map = Set.init(allocator);
    defer map.deinit();
    try map.ensureTotalCapacity(@intCast(dimension * dimension));

    var p1_result: u32 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    var size: usize = 0;
    while (in_iter.next()) |raw_point| {
        var point_iter = std.mem.tokenizeScalar(u8, raw_point, ',');
        const left = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        const right = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        const point = Point.init(right, left);
        map.putAssumeCapacity(point, {});
        if (size == max_bytes) {
            p1_result = try part1(allocator, map, dimension, Point.init(dimension - 1, dimension - 1));
        }
        size += 1;
    }
    printa(p1_result);
}

test "p2" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d18t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const dimension: CT = 6 + 1;
    var map = Set.init(allocator);
    defer map.deinit();
    try map.ensureTotalCapacity(@intCast(dimension * dimension));

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);

    while (in_iter.next()) |raw_point| {
        var point_iter = std.mem.tokenizeScalar(u8, raw_point, ',');
        const left = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        const right = std.fmt.parseInt(CT, point_iter.next().?, 10) catch unreachable;
        const point = Point.init(right, left);
        map.putAssumeCapacity(point, {});
        const result = try part2(allocator, map, dimension, Point.init(dimension - 1, dimension - 1));
        printa(result);
        if (!result) {
            printa(point);
            break;
        }
    }
}
