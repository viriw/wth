const GWL_EXSTYLE = @as(i32, -20);
const GWL_STYLE = @as(i32, -16);

const WMSZ_LEFT = @as(WPARAM, 1);
const WMSZ_RIGHT = @as(WPARAM, 2);
const WMSZ_TOP = @as(WPARAM, 3);
const WMSZ_TOPLEFT = @as(WPARAM, 4);
const WMSZ_TOPRIGHT = @as(WPARAM, 5);
const WMSZ_BOTTOM = @as(WPARAM, 6);
const WMSZ_BOTTOMLEFT = @as(WPARAM, 7);
const WMSZ_BOTTOMRIGHT = @as(WPARAM, 8);

// structure definitions
// const CREATESTRUCTW = extern struct {
//     lpCreateParams: ?*anyopaque,
//     hInstance: ?HINSTANCE,
//     hMenu: ?HMENU,
//     hwndParent: ?HWND,
//     cy: i32,
//     cx: i32,
//     y: i32,
//     x: i32,
//     style: i32,
//     lpszName: [*:0]const u16,
//     lpszClass: [*:0]const u16,
//     dwExStyle: u32,
// };

pub const Window = struct {
    resize_hook: ?wth.Window.ResizeHook,
};

// -- utility functions --

// -- windowproc and friends --

const fiber_proc_stack_size = 1024; // TODO: probably drop this

fn windowProcMeta(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) std.mem.Allocator.Error!LRESULT {
    switch (message) {
        WM_SIZING => {
            const window = windowFromHwnd(hwnd);
            if (window.resize_hook) |hook| {
                const rect: *RECT = @ptrFromInt(@as(usize, @bitCast(lparam)));
                var new = @Vector(2, wth.Window.Coordinate){
                    @intCast(rect.right - rect.left),
                    @intCast(rect.bottom - rect.top),
                };
                const direction: wth.Window.ResizeDirection = switch (wparam) {
                    WMSZ_LEFT => .left,
                    WMSZ_RIGHT => .right,
                    WMSZ_TOP => .top,
                    WMSZ_TOPLEFT => .top_left,
                    WMSZ_TOPRIGHT => .top_right,
                    WMSZ_BOTTOM => .bottom,
                    WMSZ_BOTTOMLEFT => .bottom_left,
                    WMSZ_BOTTOMRIGHT => .bottom_right,
                    else => unreachable,
                };
                assert(new[0] > window.wra[0] and new[1] > window.wra[1]);
                new -= window.wra;
                new = hook(window.size, new, direction);
                new += window.wra;
                const new_rect = switch (direction) {
                    .right, .bottom, .bottom_right => .{
                        .left = rect.left,
                        .top = rect.top,
                        .right = rect.left + new[0],
                        .bottom = rect.top + new[1],
                    },
                    .left, .bottom_left => .{
                        .left = rect.right - new[0],
                        .top = rect.top,
                        .right = rect.right,
                        .bottom = rect.top + new[1],
                    },
                    .top_left => .{
                        .left = rect.right - new[0],
                        .top = rect.bottom - new[1],
                        .right = rect.right,
                        .bottom = rect.bottom,
                    },
                    .top, .top_right => .{
                        .left = rect.left,
                        .top = rect.bottom - new[1],
                        .right = rect.left + new[0],
                        .bottom = rect.bottom,
                    },
                };
                rect.* = new_rect;
            }
            return TRUE;
        },
    }
}
