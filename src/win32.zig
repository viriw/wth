//! Win32 implementation. The minimum version is Windows 10 1703 a.k.a. Build 15063 "Redstone" (April 2017).

const std = @import("std");
const wth = @import("wth.zig");

const L = std.unicode.utf8ToUtf16LeStringLiteral;

const assert = std.debug.assert;
const options = wth.options;

const Allocator = std.mem.Allocator;
const Array_List = std.ArrayListUnmanaged;

// ---

const ATOM = u16;
const BOOL = i32;
const HANDLE = *anyopaque;
const HBRUSH = *opaque {};
const HCURSOR = *opaque {};
const HDC = *opaque {};
const HICON = *opaque {};
const HINSTANCE = *opaque {};
const HMENU = *opaque {};
const HMONITOR = *opaque {};
const HRESULT = i32;
const HWND = *opaque {};
const LPARAM = usize; // historically signed, isn't used as signed, used as ptr
const LRESULT = usize; // see LPARAM, "misdefined" for consistency with it
const WNDPROC = *const fn (HWND, u32, WPARAM, LPARAM) callconv(WINAPI) LRESULT;
const WPARAM = usize;

const IMAGE_DOS_HEADER = extern struct {
    e_magic: u16,
    e_cblp: u16,
    e_cp: u16,
    e_crlc: u16,
    e_cparhdr: u16,
    e_minalloc: u16,
    e_maxalloc: u16,
    e_ss: u16,
    e_sp: u16,
    e_csum: u16,
    e_ip: u16,
    e_cs: u16,
    e_lfarlc: u16,
    e_ovno: u16,
    e_res: [4]u16,
    e_oemid: u16,
    e_oeminfo: u16,
    e_res2: [10]u16,
    e_lfanew: i32,
};
const MINMAXINFO = extern struct {
    ptReserved: POINT,
    ptMaxSize: POINT,
    ptMaxPosition: POINT,
    ptMinTrackSize: POINT,
    ptMaxTrackSize: POINT,
};
const MSG = extern struct {
    hwnd: ?HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt: POINT,
};
const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: BOOL,
    rcPaint: RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]u8,
};
const POINT = extern struct {
    x: i32,
    y: i32,
};
const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};
const TRACKMOUSEEVENT = extern struct {
    cbSize: u32,
    dwFlags: u32,
    hwndTrack: HWND,
    dwHoverTime: u32,
};
const WINDOWPOS = extern struct {
    hwnd: HWND,
    hwndInsertAfter: ?HWND,
    x: i32,
    y: i32,
    cx: i32,
    cy: i32,
    flags: u32,
};
const WNDCLASSEXW = extern struct {
    cbSize: u32,
    style: u32,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]align(1) const u16,
    hIconSm: ?HICON,
};

const CS_CLASSDC = @as(u32, 0x0040);
const CW_USEDEFAULT = @as(i32, -2147483648);
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = @as(isize, -4);
const DWMWA_USE_IMMERSIVE_DARK_MODE = @as(u32, 20);
const DWMWA_WINDOW_CORNER_PREFERENCE = @as(u32, 33);
const FALSE = @as(BOOL, 0);
const GWL_EXSTYLE = @as(i32, -20);
const GWL_STYLE = @as(i32, -16);
const HTCLIENT = @as(u32, 1);
const IDC_APPSTARTING = @as(u16, 32650);
const IDC_ARROW = @as(u16, 32512);
const IDC_CROSS = @as(u16, 32515);
const IDC_HAND = @as(u16, 32649);
// const IDC_HELP = @as(u16, 32651);
const IDC_IBEAM = @as(u16, 32513);
// const IDC_NO = @as(u16, 32648);
const IDC_SIZEALL = @as(u16, 32646);
const IDC_SIZENESW = @as(u16, 32643);
const IDC_SIZENS = @as(u16, 32645);
const IDC_SIZENWSE = @as(u16, 32642);
const IDC_SIZEWE = @as(u16, 32644);
// const IDC_UPARROW = @as(u16, 32516);
const IDC_WAIT = @as(u16, 32514);
const IMAGE_CURSOR = @as(u32, 2);
const LR_DEFAULTSIZE = @as(u32, 0x00000040);
const LR_SHARED = @as(u32, 0x00008000);
const MDT_EFFECTIVE_DPI = @as(i32, 0);
const MF_BYCOMMAND = @as(u32, 0);
const MF_DISABLED = @as(u32, 2);
const MF_ENABLED = @as(u32, 0);
const MF_GRAYED = @as(u32, 1);
const MONITOR_DEFAULTTOPRIMARY = @as(u32, 1);
const PM_REMOVE = @as(u32, 1);
const S_OK = @as(HRESULT, 0);
const SC_CLOSE = @as(u32, 0xF060);
// const SW_HIDE = @as(i32, 0);
const SW_SHOW = @as(i32, 5);
const SWP_FRAMECHANGED = @as(u32, 32);
const SWP_HIDEWINDOW = @as(u32, 128);
const SWP_NOACTIVATE = @as(u32, 16);
const SWP_NOMOVE = @as(u32, 2);
// const SWP_NOSENDCHANGING = @as(u32, 1024);
const SWP_NOSIZE = @as(u32, 1);
const SWP_NOZORDER = @as(u32, 4);
const SWP_SHOWWINDOW = @as(u32, 64);
const TME_LEAVE = @as(u32, 2);
const TRUE = @as(BOOL, 1);
const WINAPI = std.os.windows.WINAPI;
const WM_ACTIVATE = @as(u32, 0x06);
const WM_CLOSE = @as(u32, 0x10);
const WM_DESTROY = @as(u32, 0x02);
const WM_DPICHANGED = @as(u32, 0x02E0);
const WM_ENTERSIZEMOVE = @as(u32, 0x0231);
const WM_EXITSIZEMOVE = @as(u32, 0x0232);
const WM_GETMINMAXINFO = @as(u32, 0x24);
const WM_KILLFOCUS = @as(u32, 0x08);
const WM_LBUTTONDOWN = @as(u32, 0x0201);
const WM_LBUTTONUP = @as(u32, 0x0202);
const WM_MBUTTONDOWN = @as(u32, 0x0207);
const WM_MBUTTONUP = @as(u32, 0x0208);
const WM_MOUSELEAVE = @as(u32, 0x02A3);
const WM_MOUSEMOVE = @as(u32, 0x0200);
const WM_NCCREATE = @as(u32, 0x81);
const WM_PAINT = @as(u32, 0x0F);
const WM_QUIT = @as(u32, 0x12);
const WM_RBUTTONDOWN = @as(u32, 0x0204);
const WM_RBUTTONUP = @as(u32, 0x0205);
const WM_SETCURSOR = @as(u32, 0x20);
const WM_SETFOCUS = @as(u32, 0x07);
const WM_SIZING = @as(u32, 0x0214);
const WM_TIMER = @as(u32, 0x0113);
const WM_USER = @as(u32, 0x0400);
const WM_WINDOWPOSCHANGED = @as(u32, 0x0047);
const WM_WINDOWPOSCHANGING = @as(u32, 0x0046);
const WM_XBUTTONDOWN = @as(u32, 0x020B);
const WM_XBUTTONUP = @as(u32, 0x020C);
const WS_CAPTION = @as(u32, 0x00C00000);
const WS_MAXIMIZEBOX = @as(u32, 0x00010000);
const WS_MINIMIZEBOX = @as(u32, 0x00020000);
const WS_OVERLAPPED = @as(u32, 0x00000000);
const WS_POPUP = @as(u32, 0x80000000);
const WS_SYSMENU = @as(u32, 0x00080000);
const WS_THICKFRAME = @as(u32, 0x00040000);
const WS_VISIBLE = @as(u32, 0x10000000);

extern "dwmapi" fn DwmSetWindowAttribute(hwnd: HWND, dwAttribute: u32, pvAttribute: *const anyopaque, cbAttribute: u32) callconv(WINAPI) HRESULT;
extern "kernel32" fn ConvertFiberToThread() callconv(WINAPI) BOOL;
extern "kernel32" fn ConvertThreadToFiber(lpParameter: ?*anyopaque) callconv(WINAPI) ?*anyopaque;
extern "kernel32" fn CreateFiber(dwStackSize: usize, lpStartAddress: *const fn (?*anyopaque) callconv(WINAPI) void, lpParameter: ?*anyopaque) callconv(WINAPI) ?*anyopaque;
extern "kernel32" fn DeleteFiber(lpFiber: *anyopaque) callconv(WINAPI) void;
extern "kernel32" fn SwitchToFiber(lpFiber: *anyopaque) callconv(WINAPI) void;
extern "ntdll" fn RtlGetNtVersionNumbers(*u32, *u32, *u32) callconv(WINAPI) void;
extern "shcore" fn GetDpiForMonitor(hmonitor: HMONITOR, dpiType: i32, dpiX: *u32, dpiY: *u32) HRESULT;
extern "user32" fn AdjustWindowRectExForDpi(lpRect: *RECT, dwStyle: u32, bMenu: BOOL, dwExStyle: u32, dpi: u32) callconv(WINAPI) BOOL;
extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(WINAPI) ?HDC;
extern "user32" fn CreateWindowExW(dwExStyle: u32, lpClassName: [*:0]align(1) const u16, lpWindowName: [*:0]const u16, dwStyle: u32, X: i32, Y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(WINAPI) BOOL;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(WINAPI) LRESULT;
extern "user32" fn EnableMenuItem(hMenu: HMENU, uIDEnableItem: u32, uEnable: u32) callconv(WINAPI) BOOL;
extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(WINAPI) BOOL;
extern "user32" fn GetClassInfoExW(hInstance: HINSTANCE, lpszClass: [*:0]const u16, lpwcx: *WNDCLASSEXW) callconv(WINAPI) BOOL;
extern "user32" fn GetSystemMenu(hWnd: HWND, bRevert: BOOL) callconv(WINAPI) ?HMENU;
extern "user32" fn GetWindowRect(hWnd: HWND, lpRect: *RECT) callconv(WINAPI) BOOL;
extern "user32" fn KillTimer(hWnd: ?HWND, uIDEvent: usize) callconv(WINAPI) BOOL;
extern "user32" fn LoadImageW(hInst: ?HINSTANCE, name: [*:0]align(1) const u16, @"type": u32, cx: i32, cy: i32, fuLoad: u32) callconv(WINAPI) ?HANDLE;
extern "user32" fn MonitorFromPoint(pt: POINT, dwFlags: u32) callconv(WINAPI) ?HMONITOR;
extern "user32" fn MonitorFromWindow(hwnd: HWND, dwFlags: u32) ?HMONITOR;
extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: u32, wMsgFilterMax: u32, wRemoveMsg: u32) callconv(WINAPI) BOOL;
extern "user32" fn PostMessageW(hWnd: ?HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) BOOL;
extern "user32" fn RegisterClassExW(unnamedParam1: *const WNDCLASSEXW) callconv(WINAPI) ATOM;
extern "user32" fn SetCursor(hCursor: ?HCURSOR) ?HCURSOR;
extern "user32" fn SetProcessDpiAwarenessContext(dpiContext: isize) callconv(WINAPI) BOOL;
extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: u32, lpTimerFunc: ?*anyopaque) callconv(WINAPI) usize;
extern "user32" fn SetWindowPos(hWnd: HWND, hWndInsertAfter: ?HWND, X: i32, Y: i32, cx: i32, cy: i32, uFlags: u32) callconv(WINAPI) BOOL;
extern "user32" fn TrackMouseEvent(lpEventTrack: *TRACKMOUSEEVENT) callconv(WINAPI) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(WINAPI) BOOL;
extern "user32" fn UnregisterClassW(lpClassName: [*:0]align(1) const u16, hInstance: HINSTANCE) callconv(WINAPI) BOOL;

// Wrapper for the API set that manipulates window class and instance storage.
//
// History lesson: Classic WINAPI, you have SetClassLongW and friends, taking LONG, a 32-bit type definition.
// When Microsoft upgraded from 32 to 64 bit, they realised pointers needed to fit into these integers sometimes.
// They added a new set of functions, SetClassLongPtrW and so on, taking LONG_PTR, but only defined it for 64-bit.
// Their solution for using those functions on 32-bit was to fucking #define SetClassLongPtrW SetClassLongW.
// However, the signatures are incompatible. So they need to be fixed in practically every language binding.
// It's also the case that SetClassLongPtrW takes a LONG_PTR but the "old value" is a ULONG_PTR. We ignore this.
const user32_extra = struct {
    // pub extern "user32" fn GetClassLongPtrW(hWnd: HWND, nIndex: i32) callconv(WINAPI) usize;
    // pub extern "user32" fn GetClassLongW(hWnd: HWND, nIndex: i32) callconv(WINAPI) u32;
    // pub extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: i32) callconv(WINAPI) usize;
    // pub extern "user32" fn GetWindowLongW(hWnd: HWND, nIndex: i32) callconv(WINAPI) u32;
    // pub extern "user32" fn SetClassLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: usize) callconv(WINAPI) usize;
    // pub extern "user32" fn SetClassLongW(hWnd: HWND, nIndex: i32, dwNewLong: u32) callconv(WINAPI) u32;
    pub extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: usize) callconv(WINAPI) usize;
    pub extern "user32" fn SetWindowLongW(hWnd: HWND, nIndex: i32, dwNewLong: u32) callconv(WINAPI) u32;
};
// const GetClassLongPtrW = if (@sizeOf(*anyopaque) > 4) user32_extra.GetClassLongPtrW else user32_extra.GetClassLongW;
// const GetWindowLongPtrW = if (@sizeOf(*anyopaque) > 4) user32_extra.GetWindowLongPtrW else user32_extra.GetWindowLongW;
// const SetClassLongPtrW = if (@sizeOf(*anyopaque) > 4) user32_extra.SetClassLongPtrW else user32_extra.SetClassLongW;
const SetWindowLongPtrW = if (@sizeOf(*anyopaque) > 4) user32_extra.SetWindowLongPtrW else user32_extra.SetWindowLongW;

// ---

const lpcwstr_stack_buffer_size = 4096;

const global = struct {
    var allocator: Allocator = undefined;
    var event_buffer: Array_List(wth.Event) = .{};
    var main_fiber: if (options.win32_fibers) *anyopaque else noreturn = undefined;
    var message_fiber: if (options.win32_fibers) *anyopaque else noreturn = undefined;
    var win11_21h2_or_later: bool = undefined; // Build 22000 "Sun Valley" (October 2021)
    var window_class: ATOM = undefined;
    var window_head: ?*Window = null;
    var window_proc_error: Window_Proc_Error!void = void{};
    var wm_quit_posted: bool = false;
};

pub fn clear() void {
    global.event_buffer.items.len = 0;
}

pub fn deinit() void {
    if (options.win32_fibers) {
        SwitchToFiber(global.message_fiber);
        DeleteFiber(global.message_fiber);
        assert(ConvertFiberToThread() != 0);
    } else {
        process_messages();
    }
    global.event_buffer.deinit(global.allocator);
    global.window_proc_error = void{};
    assert(UnregisterClassW(@ptrFromInt(global.window_class), image_base()) != 0);
}

pub fn events() []const wth.Event {
    return global.event_buffer.items;
}

pub fn get_allocator() Allocator {
    return global.allocator;
}

pub fn init(allocator: Allocator, _: wth.Init_Options) wth.Init_Error!void {
    global.allocator = allocator;

    try global.event_buffer.ensureTotalCapacity(global.allocator, options.event_buffer_reserve);

    // use undocumented ntdll function to get the build number. some msvcrt's reference it, so it's okay
    // the top 4 bits of the build number indicate the type of windows build (0xC debug, 0xF retail)
    var major: u32 = undefined;
    var minor: u32 = undefined;
    var build: u32 = undefined;
    RtlGetNtVersionNumbers(&major, &minor, &build);
    build &= ~@as(u32, 0xF0000000);

    // n.b. the implicit minimum is v10.0.15063, as SetProcessDpiAwarenessContext is referenced
    // if this was not the case, the version check below would not be entirely correct
    global.win11_21h2_or_later = major > 10 or minor > 0 or build >= 22000;

    // this can fail if you set it via the executable manifest, the solution is to not do that
    assert(SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2) != 0);

    const wcx = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = CS_CLASSDC,
        .lpfnWndProc = window_proc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = image_base(),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        // TODO: I don't think all class names are allowed? Some pre-registered ones, I think?
        // TODO: I don't think the above comment is true, since it's HINSTANCE-paired.
        .lpszClassName = L("wth"),
        .hIconSm = null,
    };
    global.window_class = RegisterClassExW(&wcx);
    if (global.window_class == 0) return error.SystemResources;

    if (options.win32_fibers) {
        // other reasons are possible for this to fail, mainly another library (or the user) already doing fibers
        // if this is the case then the error will be pretty consistent and obvious and you can discuss integration
        global.main_fiber = ConvertThreadToFiber(null) orelse return error.SystemResources;
        errdefer assert(ConvertFiberToThread() != 0);
        global.message_fiber = CreateFiber(0, message_fiber_proc, null) orelse return error.SystemResources;
    }
}

pub fn sync() wth.Sync_Error!void {
    if (options.win32_fibers) {
        SwitchToFiber(global.message_fiber);
    } else {
        process_messages();
    }
    if (global.wm_quit_posted) {
        return error.Shutdown;
    }
    const err = global.window_proc_error;
    global.window_proc_error = void{};
    try err;
}

// ---

pub const Win32_Corner_Preference = enum {
    default,
    do_not_round,
    round,
    round_small,
};

pub const Window = struct {
    controls: wth.Window.Controls,
    cursor: ?HCURSOR,
    dpi: u32,
    hwnd: ?HWND,
    is_focused: bool,
    is_mouse_in_client_area: bool,
    mouse_position: @Vector(2, wth.Window.Coordinate),
    next: if (options.multi_window) ?*Window else void,
    position: @Vector(2, i32),
    size: @Vector(2, wth.Window.Coordinate),
    style: u32,
    style_ex: u32,
    wra: RECT,

    pub fn emplace(
        window: *Window,
        create_options: wth.Window.Create_Options,
    ) wth.Window.Create_Error!void {
        window.next = if (options.multi_window) global.window_head else null;
        global.window_head = window;
        errdefer global.window_head = window.next;

        window.controls = create_options.controls;
        window.cursor = load_system_cursor(create_options.cursor);
        window.dpi = monitor_dpi(MonitorFromPoint(.{ .x = 0, .y = 0 }, MONITOR_DEFAULTTOPRIMARY).?);
        window.hwnd = null;
        window.is_focused = false;
        window.is_mouse_in_client_area = false;
        window.mouse_position = .{ 0, 0 };
        window.position = .{ 0, 0 };
        window.size = create_options.size;

        // initialises .style{,_ex} and .wra, must be called in this order
        window.refresh_styles();
        window.refresh_wra();

        var sf = std.heap.stackFallback(lpcwstr_stack_buffer_size, global.allocator);
        var sfa = sf.get();
        const title = try utf8_to_utf16le_z(sfa, create_options.title);
        defer sfa.free(title);

        var width, var height = window.size + wra_rl_bt(window.wra);
        window.hwnd = CreateWindowExW(
            window.style_ex,
            @ptrFromInt(global.window_class),
            title.ptr,
            window.style & ~WS_VISIBLE,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            width,
            height,
            null,
            null,
            image_base(),
            null,
        ) orelse {
            const err = global.window_proc_error;
            global.window_proc_error = void{};
            try err;
            return error.SystemResources;
        };

        {
            // belt and suspenders: let's get the default monitor (again)
            // on my machine CW_USEDEFAULT always goes to the primary, but...
            const dpi = monitor_dpi(MonitorFromWindow(window.hwnd.?, MONITOR_DEFAULTTOPRIMARY).?);
            if (dpi != window.dpi) {
                window.dpi = dpi;
                window.refresh_wra();
                width, height = window.size + wra_rl_bt(window.wra);
                assert(SetWindowPos(window.hwnd.?, null, 0, 0, width, height, SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOZORDER) != 0);
            }

            var rect: RECT = undefined;
            assert(GetWindowRect(window.hwnd.?, &rect) != 0);
            window.position = .{ @intCast(rect.left), @intCast(rect.top) };
            window.size = wra_rl_bt(rect) - wra_rl_bt(window.wra);
            // TODO: push event?
        }

        window.refresh_system_menu();
        window.set_win32_corner_preference(create_options.win32_corner_preference);
        if (global.win11_21h2_or_later) {
            assert(DwmSetWindowAttribute(window.hwnd.?, DWMWA_USE_IMMERSIVE_DARK_MODE, &TRUE, @sizeOf(BOOL)) == S_OK);
        }

        if (create_options.visible) {
            window.style |= WS_VISIBLE;
            window.write_styles();
            set_visible_now(window, true);
        }
    }

    pub fn deinit(window: *Window) void {
        assert(DestroyWindow(window.hwnd.?) != 0);
        if (global.window_head.? == window) {
            global.window_head = window.next;
        } else {
            var iter = global.window_head;
            while (iter) |head| : (iter = head.next) {
                if (head.next == window) {
                    head.next = window.next;
                    break;
                }
            } else {
                unreachable;
            }
        }
    }

    pub inline fn set_controls(window: *const Window, controls: wth.Window.Controls) void {
        assert(PostMessageW(window.hwnd.?, WTH_WM_SETCONTROLS, @as(Window_Controls_Representation, @bitCast(controls)), 0) != 0);
    }

    pub inline fn set_visible(window: *Window, visible: bool) void {
        assert(PostMessageW(window.hwnd.?, WTH_WM_SETVISIBLE, @intFromBool(visible), 0) != 0);
    }

    pub inline fn set_win32_corner_preference(window: *const Window, preference: Win32_Corner_Preference) void {
        if (!global.win11_21h2_or_later) return;
        assert(DwmSetWindowAttribute(
            window.hwnd.?,
            DWMWA_WINDOW_CORNER_PREFERENCE,
            &@as(i32, @intFromEnum(preference)),
            @sizeOf(i32),
        ) == S_OK);
    }

    // ---

    fn refresh_styles(window: *Window) void {
        window.style = WS_OVERLAPPED | WS_VISIBLE;
        window.style_ex = 0;
        if (window.controls.border) {
            window.style |= WS_CAPTION | WS_SYSMENU;
        } else {
            window.style |= WS_POPUP;
        }
        window.style |= WS_MINIMIZEBOX * @intFromBool(window.controls.minimise);
        window.style |= WS_MAXIMIZEBOX * @intFromBool(window.controls.maximise);
        window.style |= WS_THICKFRAME * @intFromBool(window.controls.resize);
    }

    fn refresh_system_menu(window: *const Window) void {
        if (!window.controls.border) return;
        const state = if (window.controls.close) MF_ENABLED else MF_DISABLED | MF_GRAYED;
        _ = EnableMenuItem(GetSystemMenu(window.hwnd.?, FALSE).?, SC_CLOSE, MF_BYCOMMAND | state);
    }

    inline fn refresh_wra(window: *Window) void {
        window.wra = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
        assert(AdjustWindowRectExForDpi(&window.wra, window.style, FALSE, window.style_ex, window.dpi) != 0);
    }

    fn write_styles(window: *const Window) void {
        _ = SetWindowLongPtrW(window.hwnd.?, GWL_STYLE, window.style);
        _ = SetWindowLongPtrW(window.hwnd.?, GWL_EXSTYLE, window.style_ex);
    }
};

// ---

extern const __ImageBase: IMAGE_DOS_HEADER;
inline fn image_base() HINSTANCE {
    return @ptrCast(&__ImageBase);
}

fn load_system_cursor(cursor: ?wth.Cursor) ?HCURSOR {
    if (cursor == null) return null;
    return @ptrCast(LoadImageW(null, @ptrFromInt(switch (cursor.?) {
        .arrow => IDC_ARROW,
        .busy => IDC_WAIT,
        .cross => IDC_CROSS,
        .hand => IDC_HAND,
        .i_beam => IDC_IBEAM,
        .move => IDC_SIZEALL,
        .size_nesw => IDC_SIZENESW,
        .size_ns => IDC_SIZENS,
        .size_nwse => IDC_SIZENWSE,
        .size_we => IDC_SIZEWE,
        .working => IDC_APPSTARTING,
    }), IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED).?);
}

fn monitor_dpi(hmonitor: HMONITOR) u32 {
    var xdpi: u32, var ydpi: u32 = .{ undefined, undefined };
    assert(GetDpiForMonitor(hmonitor, MDT_EFFECTIVE_DPI, &xdpi, &ydpi) == S_OK);
    return xdpi;
}

fn os_mouse_event(hwnd: HWND, lparam: LPARAM, button: wth.Mouse_Button, what: enum { down, up }) Allocator.Error!LRESULT {
    const window = window_from_hwnd(hwnd);
    const dword: u32 = @truncate(@as(usize, @bitCast(lparam)));
    const position = @Vector(2, wth.Window.Coordinate){
        @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword)))), 0, window.size[0])),
        @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword >> 16)))), 0, window.size[1])),
    };
    window.mouse_position = position;
    const payload = wth.Event.Mouse_Button_OS{
        .button = button,
        .position = position,
        .window = ww(window),
    };
    try push_event(switch (what) {
        .down => .{ .mouse_button_press_os = payload },
        .up => .{ .mouse_button_release_os = payload },
    });
    return 0;
}

// TODO: Would inlining this be better to not copy the Event?
fn push_event(event: wth.Event) Allocator.Error!void {
    try global.event_buffer.append(global.allocator, event);
}

fn set_visible_now(window: *Window, visible: bool) void {
    const base_mask = SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER;
    const visible_bit = if (visible) SWP_SHOWWINDOW else SWP_HIDEWINDOW;
    assert(SetWindowPos(window.hwnd.?, null, 0, 0, 0, 0, base_mask | visible_bit) != 0); // TODO: maybe nosendchanging here?
}

inline fn utf8_to_utf16le_z(allocator: Allocator, utf8: []const u8) Allocator.Error![:0]u16 {
    return std.unicode.utf8ToUtf16LeWithNull(allocator, utf8) catch |err| switch (err) {
        error.InvalidUtf8 => unreachable,
        error.OutOfMemory => return error.OutOfMemory,
    };
}

fn window_from_hwnd(hwnd: HWND) *Window {
    var head = global.window_head;
    if (options.multi_window) {
        while (head) |window| : (head = window.next) {
            if (window.hwnd) |x| {
                if (x == hwnd) {
                    return window;
                }
            } else {
                // must be here before CreateWindowExW returned
                // in that case, it has to be the right window
                return window;
            }
        } else {
            unreachable;
        }
    } else {
        return head.?;
    }
}

inline fn wra_rl_bt(rect: RECT) @Vector(2, wth.Window.Coordinate) {
    return .{ @intCast(rect.right - rect.left), @intCast(rect.bottom - rect.top) };
}

// helper for a SetWindowPos transition maintaining client area position for different window rectangle adjustments
fn wra_xy_transition(old_wra: RECT, old_position: @Vector(2, i32), new_wra: RECT) @Vector(2, i32) { // -> new_position
    return .{
        (old_position[0] - old_wra.left) + new_wra.left,
        (old_position[1] - old_wra.top) + new_wra.top,
    };
}

inline fn ww(window: *Window) if (options.multi_window) *wth.Window else void {
    if (options.multi_window) {
        return @fieldParentPtr(wth.Window, "impl", window);
    }
}

// ---

fn message_fiber_proc(_: ?*anyopaque) callconv(WINAPI) void {
    while (true) {
        process_messages();
        SwitchToFiber(global.main_fiber);
    }
}

fn process_messages() void {
    var msg: MSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        if (options.text_input) {
            _ = TranslateMessage(&msg);
        }
        if (msg.message != WM_QUIT) {
            _ = DispatchMessageW(&msg);
            if (global.window_proc_error) {} else |_| {
                // @cold
                return;
            }
        } else {
            // @cold
            global.wm_quit_posted = true;
        }
    }
}

fn window_proc(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(WINAPI) LRESULT {
    return window_proc_real(hwnd, message, wparam, lparam) catch |err| blk: {
        global.window_proc_error = err;
        break :blk 0;
    };
}

// ---

const fiber_timer_id = 1; // must be >= 1
const Window_Controls_Representation = @Type(.{ .Int = .{
    .signedness = .unsigned,
    .bits = @bitSizeOf(wth.Window.Controls),
} });
const Window_Proc_Error = Allocator.Error;

const WTH_WM_SETCONTROLS = WM_USER + 0;
const WTH_WM_SETVISIBLE = WM_USER + 1;

fn window_proc_real(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) Window_Proc_Error!LRESULT {
    switch (message) {
        // TODO: that ncsizemove grindset
        // magic spell to have fibers allow us to size/move without blocking sync()
        // TODO: explain what and how ^^^^^^^??? (i dont feel like it rn)
        WM_ENTERSIZEMOVE => {
            if (options.win32_fibers) {
                assert(SetTimer(hwnd, fiber_timer_id, 1, null) != 0);
            }
            return 0;
        },
        WM_EXITSIZEMOVE => {
            if (options.win32_fibers) {
                assert(KillTimer(hwnd, fiber_timer_id) != 0);
            }
            return 0;
        },
        WM_TIMER => {
            if (options.win32_fibers and wparam == fiber_timer_id) {
                SwitchToFiber(global.main_fiber);
            }
            return 0;
        },

        WM_PAINT => {
            // the system will flood the queue with this message until we call BeginPaint calm it down
            // it doesn't matter if absolutely nothing is done, you need to do this or it will not stop
            var paintstruct: PAINTSTRUCT = undefined;
            assert(BeginPaint(hwnd, &paintstruct) != null);
            assert(EndPaint(hwnd, &paintstruct) != 0);
            return 0;
        },

        WM_SETCURSOR => {
            const hit_test: u16 = @truncate(lparam);
            if (wparam == @intFromPtr(hwnd) and hit_test == HTCLIENT) {
                _ = SetCursor(window_from_hwnd(hwnd).cursor);
                return TRUE;
            } else {
                return DefWindowProcW(hwnd, message, wparam, lparam);
            }
        },

        WM_GETMINMAXINFO => {
            const window = window_from_hwnd(hwnd);
            const mmi: *MINMAXINFO = @ptrFromInt(lparam);
            const min = wra_rl_bt(window.wra);
            mmi.ptMinTrackSize = .{ .x = min[0] + 1, .y = min[1] + 1 };
            return 0;
        },

        WM_DPICHANGED => {
            const window = window_from_hwnd(hwnd);
            const old_wra = window.wra;
            window.dpi = @truncate(wparam & 0xFFFF); // LOWORD is X DPI
            window.refresh_wra();
            window.position = wra_xy_transition(old_wra, window.position, window.wra);
            const x, const y = window.position;
            const width, const height = window.size + wra_rl_bt(window.wra);
            assert(SetWindowPos(
                window.hwnd.?,
                null,
                x,
                y,
                width,
                height,
                SWP_NOACTIVATE | SWP_NOZORDER,
            ) != 0);
            return 0;
        },

        // ---

        WM_CLOSE => {
            try push_event(.{ .close_request = ww(window_from_hwnd(hwnd)) });
            return 0;
        },

        WM_ACTIVATE => {
            // MSDN says:
            // > The high-order word specifies the minimised state of the window being activated or deactivated.
            // > A nonzero value indicates the window is minimised.
            //
            // This doesn't work correctly in all situations, because of course it doesn't.
            // You can get some great message combos by clicking on the taskbar icon mid minimise animation, such as:
            // 1) WM_INACTIVE (HIWORD == 0) <- unfocused, not minimised (but, it is...)
            // 2) WM_ACTIVATE (HIWORD != 0) <- focused, minimised (but, it's not...)
            // The keyboard focus message WM_{SET,KILL}FOCUS doesn't have this issue, so we just use that instead.
            return 0;
        },
        WM_SETFOCUS => {
            try push_event(.{ .focus = ww(window_from_hwnd(hwnd)) });
            return 0;
        },
        WM_KILLFOCUS => {
            try push_event(.{ .unfocus = ww(window_from_hwnd(hwnd)) });
            return 0;
        },

        WM_WINDOWPOSCHANGED => {
            // n.b. handling this message without calling DefWindowProc means no WM_{MOVE,SIZE} sent
            const window = window_from_hwnd(hwnd);
            const info: *const WINDOWPOS = @ptrFromInt(lparam);
            if (info.flags & SWP_NOMOVE == 0) {
                window.position = .{ info.x, info.y };
            }
            if (info.flags & SWP_NOSIZE == 0) {
                window.size = .{ @intCast(info.cx), @intCast(info.cy) };
                window.size -= wra_rl_bt(window.wra);
            }
            return 0;
        },
        WM_WINDOWPOSCHANGING => {
            // For a window with the WS_OVERLAPPED or WS_THICKFRAME style,
            // the DefWindowProc function sends the WM_GETMINMAXINFO message to the window.
            // This is done to validate the new size and position of the window and to enforce
            // the CS_BYTEALIGNCLIENT and CS_BYTEALIGNWINDOW client styles.
            // By not passing the WM_WINDOWPOSCHANGING message to the DefWindowProc function,
            // an application can override these defaults.
            // TODO: ^ What the fuck does this mean? ^

            return 0;
        },

        WM_MOUSELEAVE => {
            const window = window_from_hwnd(hwnd);
            window.is_mouse_in_client_area = false;
            try push_event(.{ .mouse_leave_os = .{ .position = window.mouse_position, .window = ww(window) } });
            return 0;
        },
        WM_MOUSEMOVE => {
            // getting mouse coordinates outside of the client area is possible with some window styles, even if it shouldn't do that, so clamp it
            // things like the drop shadow count as part of the window rectangle and can sometimes send messages if it feels like, it's not documented
            const window = window_from_hwnd(hwnd);
            const dword: u32 = @truncate(lparam);
            const position = @Vector(2, wth.Window.Coordinate){
                @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword)))), 0, window.size[0])),
                @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword >> 16)))), 0, window.size[1])),
            };
            if (!window.is_mouse_in_client_area) {
                window.is_mouse_in_client_area = true;
                try push_event(.{ .mouse_enter_os = .{ .position = position, .window = ww(window) } });
                var tme_info = TRACKMOUSEEVENT{
                    .cbSize = @sizeOf(TRACKMOUSEEVENT),
                    .dwFlags = TME_LEAVE,
                    .hwndTrack = hwnd,
                    .dwHoverTime = 0,
                };
                assert(TrackMouseEvent(&tme_info) != 0);
            }
            if (position[0] != window.mouse_position[0] or position[1] != window.mouse_position[1]) {
                window.mouse_position = position;
                try push_event(.{ .mouse_move_os = .{ .position = window.mouse_position, .window = ww(window) } });
            }
            return 0;
        },

        WM_LBUTTONDOWN => return try os_mouse_event(hwnd, lparam, .left, .down),
        WM_LBUTTONUP => return try os_mouse_event(hwnd, lparam, .left, .up),
        WM_RBUTTONDOWN => return try os_mouse_event(hwnd, lparam, .right, .down),
        WM_RBUTTONUP => return try os_mouse_event(hwnd, lparam, .right, .up),
        WM_MBUTTONDOWN => return try os_mouse_event(hwnd, lparam, .middle, .down),
        WM_MBUTTONUP => return try os_mouse_event(hwnd, lparam, .middle, .up),
        WM_XBUTTONDOWN, WM_XBUTTONUP => return try os_mouse_event(
            hwnd,
            lparam,
            switch ((wparam >> 16) & 0xFFFF) {
                1 => wth.Mouse_Button.x1,
                2 => wth.Mouse_Button.x2,
                else => return 0, // nonsense
            },
            if (message == WM_XBUTTONDOWN) .down else .up,
        ),

        WTH_WM_SETCONTROLS => {
            const window = window_from_hwnd(hwnd);
            const old_wra = window.wra;
            window.controls = @bitCast(@as(Window_Controls_Representation, @truncate(wparam)));
            window.refresh_styles();
            window.refresh_wra();
            window.write_styles();
            window.position = wra_xy_transition(old_wra, window.position, window.wra);
            const x, const y = window.position;
            const width, const height = window.size + wra_rl_bt(window.wra);
            assert(SetWindowPos(
                hwnd,
                null,
                x,
                y,
                width,
                height,
                SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOZORDER,
            ) != 0);
            return 0;
        },
        WTH_WM_SETVISIBLE => {
            set_visible_now(window_from_hwnd(hwnd), wparam != 0);
            return 0;
        },

        else => return DefWindowProcW(hwnd, message, wparam, lparam),
    }
    return DefWindowProcW(hwnd, message, wparam, lparam);
}
