const std = @import("std");

const Response = struct {
    code: u16,
    message: []const u8,
};

const responses = [_]Response{
    Response{ .code = 220, .message = "220 SMTP Server Ready\r\n" },
    Response{ .code = 250, .message = "250 OK\r\n" },
    Response{ .code = 354, .message = "354 Start mail input; end with <CRLF>.<CRLF>\r\n" },
    Response{ .code = 221, .message = "221 Bye\r\n" },
    Response{ .code = 250, .message = "250 AUTH PLAIN\r\n" },
    Response{ .code = 250, .message = "250 ubuntu-s-1vcpu-512mb-10gb-sfo3-01 Nice to meet you\r\n" },
    Response{ .code = 250, .message = "250 AUTH PLAIN\r\n" },
    Response{ .code = 334, .message = "334\r\n" },
};

var buf: [512]u8 = undefined;

fn sendResponse(out_stream: anytype, response: Response) !void {
    const end: usize = response.message.len;
    @memcpy(buf[0..end], response.message);
    std.debug.print("-->{s}", .{buf});
    try out_stream.writeAll(buf[0..end]);
}

pub fn main() !void {
    const options = std.net.StreamServer.Options{};
    var listener = std.net.StreamServer.init(options);
    const addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 2525);

    defer listener.deinit();
    try listener.listen(addr);

    std.debug.print("SMTP server is running on port 2525\n", .{});

    while (true) {
        var client = try listener.accept();
        std.debug.print("New client connected\n", .{});
        handleClient(&client) catch |err| {
            std.debug.print("Error handling client: {any}\n", .{err});
        };
    }
}

fn handleClient(client: *std.net.StreamServer.Connection) !void {
    // defer client.stream.deinit();
    // const allocator = std.heap.page_allocator;

    try sendResponse(client.stream.writer(), responses[0]);

    var buffer: [1024]u8 = undefined;
    while (true) {
        const read_bytes = try client.stream.reader().readUntilDelimiterOrEof(buffer[0..], '\n');
        const command = buffer[0..read_bytes.?.len];

        std.debug.print("<--Received command: {s}\n", .{command});

        if (std.mem.startsWith(u8, command, "HELO") or std.mem.startsWith(u8, command, "EHLO")) {
            try client.stream.writeAll("250-Hello\r\n250 AUTH PLAIN\r\n");
        } else if (std.mem.startsWith(u8, command, "AUTH")) {
            try sendResponse(client.stream.writer(), responses[7]);
            const _read_bytes = try client.stream.reader().readUntilDelimiterOrEof(buffer[0..], '\n');
            const _command = buffer[0.._read_bytes.?.len];
            try client.stream.writeAll("235 Authentication successful\r\n");
            std.debug.print("++Received command: {s}\n", .{_command});
        } else if (std.mem.startsWith(u8, command, "MAIL FROM:")) {
            try sendResponse(client.stream.writer(), responses[1]);
        } else if (std.mem.startsWith(u8, command, "RCPT TO:")) {
            try sendResponse(client.stream.writer(), responses[1]);
        } else if (std.mem.startsWith(u8, command, "DATA")) {
            try sendResponse(client.stream.writer(), responses[2]);
            const data_bytes = try client.stream.reader().readUntilDelimiterOrEof(buffer[0..], '.');
            std.debug.print("Received data: {s}\n", .{buffer[0..data_bytes.?.len]});
            try sendResponse(client.stream.writer(), responses[1]);
        } else if (std.mem.startsWith(u8, command, "QUIT")) {
            try sendResponse(client.stream.writer(), responses[3]);
            client.stream.close();
            break;
        } else {
            // Default response for unrecognized commands

            // try sendResponse(client.stream.writer(), responses[3]);
        }
    }
}
