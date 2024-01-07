//! Win32 implementation. The minimum version is Windows 10 1607 (Build 14393; April 2016; Redstone / "Anniversary Update").

const root = @import("root");
const std = @import("std");
const wth = @import("../wth.zig");

const assert = std.debug.assert;
const WINAPI = std.os.windows.WINAPI;

// TODO: replace with actual build flags at some point. hardcoding now for testing
const __flags = @import("../__flags.zig");

// type definitions
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
const LPARAM = isize;
const LRESULT = isize;
const WNDPROC = *const fn (HWND, u32, WPARAM, LPARAM) callconv(WINAPI) LRESULT;
const WPARAM = usize;

// typed constants
const CW_USEDEFAULT = @as(i32, -2147483648);
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = @as(isize, -3);
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = @as(isize, -4);
const DWMWA_USE_IMMERSIVE_DARK_MODE = @as(u32, 20);
const DWMWA_WINDOW_CORNER_PREFERENCE = @as(u32, 33);
const FALSE = @as(BOOL, 0);
const GWL_EXSTYLE = @as(i32, -20);
const GWL_STYLE = @as(i32, -16);
const HTCLIENT = @as(u32, 1);
const IDC_APPSTARTING = 32650;
const IDC_ARROW = 32512;
const IDC_CROSS = 32515;
const IDC_HAND = 32649;
// const IDC_HELP = 32651;
const IDC_IBEAM = 32513;
// const IDC_NO = 32648;
const IDC_SIZEALL = 32646;
const IDC_SIZENESW = 32643;
const IDC_SIZENS = 32645;
const IDC_SIZENWSE = 32642;
const IDC_SIZEWE = 32644;
// const IDC_UPARROW = 32516;
const IDC_WAIT = 32514;
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
const SW_HIDE = @as(i32, 0);
const SW_SHOW = @as(i32, 5);
const SWP_FRAMECHANGED = @as(u32, 32);
const SWP_NOACTIVATE = @as(u32, 16);
const SWP_NOMOVE = @as(u32, 2);
const SWP_NOSENDCHANGING = @as(u32, 1024);
const SWP_NOSIZE = @as(u32, 1);
const SWP_NOZORDER = @as(u32, 4);
const SWP_SHOWWINDOW = @as(u32, 64);
const TME_LEAVE = @as(u32, 2);
const TRUE = @as(BOOL, 1);
const WM_CLOSE = @as(u32, 16);
const WM_DESTROY = @as(u32, 2);
const WM_SIZE = @as(u32, 5);
const WM_GETMINMAXINFO = @as(u32, 36);
const WM_DPICHANGED = @as(u32, 736);
const WM_ENTERSIZEMOVE = @as(u32, 561);
const WM_EXITSIZEMOVE = @as(u32, 562);
const WM_NCCREATE = @as(u32, 129);
const WM_QUIT = @as(u32, 18);
const WM_TIMER = @as(u32, 275);
const WM_MOUSEMOVE = @as(u32, 512);
const WM_SIZING = @as(u32, 532);
const WM_SETCURSOR = @as(u32, 32);
const WM_MOUSELEAVE = @as(u32, 675);
const WM_ACTIVATE = @as(u32, 6);
const WM_SETFOCUS = @as(u32, 7);
const WM_KILLFOCUS = @as(u32, 8);
const WM_PAINT = @as(u32, 15);
const WM_LBUTTONDOWN = @as(u32, 513);
const WM_LBUTTONUP = @as(u32, 514);
const WM_MBUTTONDOWN = @as(u32, 519);
const WM_MBUTTONUP = @as(u32, 520);
const WM_RBUTTONDOWN = @as(u32, 516);
const WM_RBUTTONUP = @as(u32, 517);
const WM_XBUTTONDOWN = @as(u32, 523);
const WM_XBUTTONUP = @as(u32, 524);

const WMSZ_LEFT = @as(WPARAM, 1);
const WMSZ_RIGHT = @as(WPARAM, 2);
const WMSZ_TOP = @as(WPARAM, 3);
const WMSZ_TOPLEFT = @as(WPARAM, 4);
const WMSZ_TOPRIGHT = @as(WPARAM, 5);
const WMSZ_BOTTOM = @as(WPARAM, 6);
const WMSZ_BOTTOMLEFT = @as(WPARAM, 7);
const WMSZ_BOTTOMRIGHT = @as(WPARAM, 8);

// TODO: Remove the ones we don't need here. I adapted these from winapi-rs with regexes (lol).
const WS_OVERLAPPED = @as(u32, 0x00000000);
const WS_POPUP = @as(u32, 0x80000000);
const WS_CHILD = @as(u32, 0x40000000);
const WS_MINIMIZE = @as(u32, 0x20000000);
const WS_VISIBLE = @as(u32, 0x10000000);
const WS_DISABLED = @as(u32, 0x08000000);
const WS_CLIPSIBLINGS = @as(u32, 0x04000000);
const WS_CLIPCHILDREN = @as(u32, 0x02000000);
const WS_MAXIMIZE = @as(u32, 0x01000000);
const WS_CAPTION = @as(u32, 0x00C00000);
const WS_BORDER = @as(u32, 0x00800000);
const WS_DLGFRAME = @as(u32, 0x00400000);
const WS_VSCROLL = @as(u32, 0x00200000);
const WS_HSCROLL = @as(u32, 0x00100000);
const WS_SYSMENU = @as(u32, 0x00080000);
const WS_THICKFRAME = @as(u32, 0x00040000);
const WS_GROUP = @as(u32, 0x00020000);
const WS_TABSTOP = @as(u32, 0x00010000);
const WS_MINIMIZEBOX = @as(u32, 0x00020000);
const WS_MAXIMIZEBOX = @as(u32, 0x00010000);
const WS_TILED = WS_OVERLAPPED;
const WS_ICONIC = WS_MINIMIZE;
const WS_SIZEBOX = WS_THICKFRAME;
const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX;
const WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU;
const WS_CHILDWINDOW = WS_CHILD;
const WS_EX_DLGMODALFRAME = @as(u32, 0x00000001);
const WS_EX_NOPARENTNOTIFY = @as(u32, 0x00000004);
const WS_EX_TOPMOST = @as(u32, 0x00000008);
const WS_EX_ACCEPTFILES = @as(u32, 0x00000010);
const WS_EX_TRANSPARENT = @as(u32, 0x00000020);
const WS_EX_MDICHILD = @as(u32, 0x00000040);
const WS_EX_TOOLWINDOW = @as(u32, 0x00000080);
const WS_EX_WINDOWEDGE = @as(u32, 0x00000100);
const WS_EX_CLIENTEDGE = @as(u32, 0x00000200);
const WS_EX_CONTEXTHELP = @as(u32, 0x00000400);
const WS_EX_RIGHT = @as(u32, 0x00001000);
const WS_EX_LEFT = @as(u32, 0x00000000);
const WS_EX_RTLREADING = @as(u32, 0x00002000);
const WS_EX_LTRREADING = @as(u32, 0x00000000);
const WS_EX_LEFTSCROLLBAR = @as(u32, 0x00004000);
const WS_EX_RIGHTSCROLLBAR = @as(u32, 0x00000000);
const WS_EX_CONTROLPARENT = @as(u32, 0x00010000);
const WS_EX_STATICEDGE = @as(u32, 0x00020000);
const WS_EX_APPWINDOW = @as(u32, 0x00040000);
const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;
const WS_EX_PALETTEWINDOW = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;
const WS_EX_LAYERED = @as(u32, 0x00080000);
const WS_EX_NOINHERITLAYOUT = @as(u32, 0x00100000);
const WS_EX_NOREDIRECTIONBITMAP = @as(u32, 0x00200000);
const WS_EX_LAYOUTRTL = @as(u32, 0x00400000);
const WS_EX_COMPOSITED = @as(u32, 0x02000000);
const WS_EX_NOACTIVATE = @as(u32, 0x08000000);

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
    lpszClassName: [*:0]const u16,
    hIconSm: ?HICON,
};

// dwmapi.dll imports
extern "dwmapi" fn DwmSetWindowAttribute(hwnd: HWND, dwAttribute: u32, pvAttribute: *const anyopaque, cbAttribute: u32) callconv(WINAPI) HRESULT;

// kernel32.dll imports
extern "kernel32" fn ConvertFiberToThread() callconv(WINAPI) BOOL;
extern "kernel32" fn ConvertThreadToFiber(lpParameter: ?*anyopaque) callconv(WINAPI) ?*anyopaque;
extern "kernel32" fn CreateFiber(dwStackSize: usize, lpStartAddress: *const fn (?*anyopaque) callconv(WINAPI) void, lpParameter: ?*anyopaque) callconv(WINAPI) ?*anyopaque;
extern "kernel32" fn DeleteFiber(lpFiber: *anyopaque) callconv(WINAPI) void;
extern "kernel32" fn SwitchToFiber(lpFiber: *anyopaque) callconv(WINAPI) void;

// ntdll.dll imports
extern "ntdll" fn RtlGetNtVersionNumbers(*u32, *u32, *u32) callconv(WINAPI) void;

// shcore.dll imports
extern "shcore" fn GetDpiForMonitor(hmonitor: HMONITOR, dpiType: i32, dpiX: *u32, dpiY: *u32) HRESULT;

// user32.dll imports
extern "user32" fn AdjustWindowRectExForDpi(lpRect: *RECT, dwStyle: u32, bMenu: BOOL, dwExStyle: u32, dpi: u32) callconv(WINAPI) BOOL;
extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(WINAPI) ?HDC;
extern "user32" fn CreateWindowExW(dwExStyle: u32, lpClassName: [*:0]const u16, lpWindowName: [*:0]const u16, dwStyle: u32, X: i32, Y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(WINAPI) BOOL;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(WINAPI) LRESULT;
extern "user32" fn EnableMenuItem(hMenu: HMENU, uIDEnableItem: u32, uEnable: u32) callconv(WINAPI) BOOL;
extern "user32" fn EnableNonClientDpiScaling(hwnd: HWND) callconv(WINAPI) BOOL;
extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(WINAPI) BOOL;
extern "user32" fn GetClassInfoExW(hInstance: HINSTANCE, lpszClass: [*:0]const u16, lpwcx: *WNDCLASSEXW) callconv(WINAPI) BOOL;
extern "user32" fn GetSystemMenu(hWnd: HWND, bRevert: BOOL) callconv(WINAPI) ?HMENU;
extern "user32" fn KillTimer(hWnd: ?HWND, uIDEvent: usize) callconv(WINAPI) BOOL;
extern "user32" fn LoadImageW(hInst: ?HINSTANCE, name: [*:0]const u16, @"type": u32, cx: i32, cy: i32, fuLoad: u32) callconv(WINAPI) ?HANDLE;
extern "user32" fn MonitorFromPoint(pt: POINT, dwFlags: u32) callconv(WINAPI) ?HMONITOR;
extern "user32" fn MonitorFromWindow(hwnd: HWND, dwFlags: u32) ?HMONITOR;
extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: u32, wMsgFilterMax: u32, wRemoveMsg: u32) callconv(WINAPI) BOOL;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(WINAPI) void; // TODO: remove this
extern "user32" fn RegisterClassExW(unnamedParam1: *const WNDCLASSEXW) callconv(WINAPI) ATOM;
extern "user32" fn SetCursor(hCursor: ?HCURSOR) ?HCURSOR;
extern "user32" fn SetThreadDpiAwarenessContext(dpiContext: isize) callconv(WINAPI) isize;
extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: u32, lpTimerFunc: ?*anyopaque) callconv(WINAPI) usize;
extern "user32" fn SetWindowPos(hWnd: HWND, hWndInsertAfter: ?HWND, X: i32, Y: i32, cx: i32, cy: i32, uFlags: u32) callconv(WINAPI) BOOL;
extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(WINAPI) BOOL;
extern "user32" fn TrackMouseEvent(lpEventTrack: *TRACKMOUSEEVENT) callconv(WINAPI) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(WINAPI) BOOL;
extern "user32" fn UnregisterClassW(lpClassName: [*:0]const u16, hInstance: HINSTANCE) callconv(WINAPI) BOOL;

// Wrapper for the API set that manipulates window class and instance storage.
//
// History lesson: Classic WINAPI, you have SetClassLongW and friends, taking LONG, a 32-bit type definition.
// When Microsoft upgraded from 32 to 64 bit, they realised pointers needed to fit into these integers sometimes.
// They added a new set of functions, SetClassLongPtrW and so on, taking LONG_PTR, but only defined it for 64-bit.
// Their solution for using those functions on 32-bit was to fucking #define SetClassLongPtrW SetClassLongW.
// However, the signatures are incompatible. So they need to be fixed in practically every language binding.
// It's also the case that SetClassLongPtrW takes a LONG_PTR but the "old value" is a ULONG_PTR. We ignore this.
const user32_extra = struct {
    // supplementary user32.dll imports
    pub extern "user32" fn GetClassLongPtrW(hWnd: HWND, nIndex: i32) callconv(WINAPI) usize;
    pub extern "user32" fn GetClassLongW(hWnd: HWND, nIndex: i32) callconv(WINAPI) u32;
    pub extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: i32) callconv(WINAPI) usize;
    pub extern "user32" fn GetWindowLongW(hWnd: HWND, nIndex: i32) callconv(WINAPI) u32;
    pub extern "user32" fn SetClassLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: usize) callconv(WINAPI) usize;
    pub extern "user32" fn SetClassLongW(hWnd: HWND, nIndex: i32, dwNewLong: u32) callconv(WINAPI) u32;
    pub extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: usize) callconv(WINAPI) usize;
    pub extern "user32" fn SetWindowLongW(hWnd: HWND, nIndex: i32, dwNewLong: u32) callconv(WINAPI) u32;
};
pub const GetClassLongPtrW = if (@sizeOf(*anyopaque) == 8) user32_extra.GetClassLongPtrW else user32_extra.GetClassLongW;
pub const GetWindowLongPtrW = if (@sizeOf(*anyopaque) == 8) user32_extra.GetWindowLongPtrW else user32_extra.GetWindowLongW;
pub const SetClassLongPtrW = if (@sizeOf(*anyopaque) == 8) user32_extra.SetClassLongPtrW else user32_extra.SetClassLongW;
pub const SetWindowLongPtrW = if (@sizeOf(*anyopaque) == 8) user32_extra.SetWindowLongPtrW else user32_extra.SetWindowLongW;

/// Current module's HINSTANCE exposed through a Microsoft linker pseudo-variable.
/// - https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483
extern const __ImageBase: IMAGE_DOS_HEADER;
inline fn imageBase() HINSTANCE {
    return @ptrCast(&__ImageBase);
}

const global = struct {
    var allocator: std.mem.Allocator = undefined;
    var event_buffer: std.ArrayListUnmanaged(wth.Event) = undefined;
    var window_proc_error: std.mem.Allocator.Error!void = undefined;
    var wm_quit_posted: bool = undefined;

    var window_head: ?*Window = undefined;

    /// Handle to the main thread as a fiber.
    var main_thread_fiber = if (__flags.win32_fibers) @as(*anyopaque, undefined) else void{};
    /// Handle to the message fiber.
    var message_fiber = if (__flags.win32_fibers) @as(*anyopaque, undefined) else void{};

    /// Whether we're at least on Windows 10 1703 (Build 15063; April 2017; Redstone / "Creators Update").
    var win10_1703_or_later: bool = undefined;
    /// Whether we're at least on Windows 11 21H2 (Build 22000; October 2021; Sun Valley).
    var win11_21h2_or_later: bool = undefined;
};

// for internal use
pub inline fn getAllocator() std.mem.Allocator {
    return global.allocator;
}

pub fn init(allocator: std.mem.Allocator, _: wth.InitOptions) wth.InitError!void {
    global.allocator = allocator;
    global.event_buffer = @TypeOf(global.event_buffer){};
    global.wm_quit_posted = false;
    global.window_proc_error = void{};
    global.window_head = null;

    var major: u32, var minor: u32, var build: u32 = .{ undefined, undefined, undefined };
    RtlGetNtVersionNumbers(&major, &minor, &build);
    build &= ~@as(u32, 0xF0000000);

    // the implicit minimum is 10.0.14393 as SetThreadDpiAwarenessContext is referenced
    var dpi_awareness_context = DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE;
    if (major > 10 or minor > 0 or build >= 15063) {
        dpi_awareness_context = DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;
        global.win10_1703_or_later = true;

        // we'll need this later to hint rounded corners (or lack thereof)
        if (build >= 22000) {
            global.win11_21h2_or_later = true;
        }
    }
    assert(SetThreadDpiAwarenessContext(dpi_awareness_context) != 0);

    if (__flags.win32_fibers) {
        // TODO: I think there's other reasons why this can happen. Investigate.
        // Probably not okay to do it if someone else has already done it, could make it a flag.
        global.main_thread_fiber = ConvertThreadToFiber(null) orelse
            return error.SystemResources;
        errdefer assert(ConvertFiberToThread() != 0);

        // TODO: Exact same thing as above.
        global.message_fiber = CreateFiber(fiber_proc_stack_size, fiberProc, null) orelse
            return error.SystemResources;
        errdefer DeleteFiber(global.message_fiber);
    }
}

pub fn deinit() void {
    if (__flags.win32_fibers) {
        SwitchToFiber(global.message_fiber);
        DeleteFiber(global.message_fiber);
        assert(ConvertFiberToThread() != 0);
    } else {
        drainMessageQueue();
    }
    global.event_buffer.deinit(global.allocator);
}

pub fn events() []const wth.Event {
    return global.event_buffer.items;
}

pub inline fn sync() wth.SyncError!void {
    global.event_buffer.items.len = 0;
    if (__flags.win32_fibers) {
        SwitchToFiber(global.message_fiber);
    } else {
        drainMessageQueue();
    }
    if (global.wm_quit_posted) {
        return error.Shutdown;
    }
    const err = global.window_proc_error;
    global.window_proc_error = void{};
    try err;
}

pub const Window = struct {
    class_atom: ATOM,
    cursor: ?HCURSOR,
    dpi: u32,
    hwnd: ?HWND,

    controls: wth.Window.Controls,
    resize_hook: ?wth.Window.ResizeHook,
    size: @Vector(2, wth.Window.Coordinate),
    wra: @Vector(2, wth.Window.Coordinate),

    ex_style: u32,
    style: u32,

    mouse_in_client_area: bool,
    mouse_position: @Vector(2, wth.Window.Coordinate),

    // intrusive linked list time!
    next: if (__flags.multi_window) ?*Window else void,

    pub fn emplace(
        window: *Window,
        options: wth.Window.CreateOptions,
    ) wth.Window.CreateError!void {
        // make new head of linked list
        if (__flags.multi_window) {
            window.next = global.window_head;
        }
        global.window_head = window;
        errdefer if (__flags.multi_window) {
            global.window_head = window.next;
        };

        var sf = std.heap.stackFallback(1024, global.allocator);
        var sfa = sf.get();

        // check if the window class exists, if not, register it
        window.class_atom, const class_created_here: bool = blk: {
            const class_name = try utf8ToUtf16LeWithNullAssumeValid(sfa, options.title);
            defer sfa.free(class_name);

            // undocumented win32 tidbit: GetClassInfo** returns the class atom to act as the BOOL here
            // this is the only way to actually look up a class by its name as the atom table is private
            // - https://devblogs.microsoft.com/oldnewthing/20041011-00/?p=37603
            // - https://devblogs.microsoft.com/oldnewthing/20150429-00/?p=44984
            var wcex: WNDCLASSEXW = undefined;
            wcex.cbSize = @sizeOf(WNDCLASSEXW);
            var class_atom: ATOM = if (__flags.multi_window) @intCast(GetClassInfoExW(imageBase(), class_name, &wcex)) else 0;
            var class_created_here = false;
            if (class_atom == 0) {
                // we can re-use the structure needed for GetClassInfoExW to actually register the window class
                wcex = .{
                    .cbSize = @sizeOf(WNDCLASSEXW),
                    .style = 0,
                    .lpfnWndProc = windowProc,
                    // store a window class reference count in its structure's tail allocation
                    .cbClsExtra = if (__flags.multi_window) @sizeOf(usize) else 0,
                    .cbWndExtra = 0,
                    .hInstance = imageBase(),
                    .hIcon = null,
                    .hCursor = null,
                    .hbrBackground = null,
                    .lpszMenuName = null,
                    // TODO: I don't think all class names are allowed? Some pre-registered ones, I think?
                    .lpszClassName = class_name.ptr,
                    .hIconSm = null,
                };
                class_atom = RegisterClassExW(&wcex);
                if (class_atom == 0) {
                    // The class does not exist if we got to this point, so it has to be this.
                    return error.SystemResources;
                }
                class_created_here = true;
            }
            break :blk .{ class_atom, class_created_here };
        };
        errdefer if (class_created_here) assert(UnregisterClassW(atomCast(window.class_atom), imageBase()) != 0);

        window.cursor = if (options.cursor) |cursor| loadSystemCursor(cursor) else null;
        window.dpi = monitorDpi(MonitorFromPoint(.{ .x = 0, .y = 0 }, MONITOR_DEFAULTTOPRIMARY).?);
        window.resize_hook = options.resize_hook;
        window.size = options.size;

        // caches style, ex_style
        window.controls = options.controls;
        window.recalculateWindowStyle();
        window.recalculateWindowRectangleAdjustment();

        // other state
        window.mouse_in_client_area = false;

        sfa = sf.get(); // reset
        const title = try utf8ToUtf16LeWithNullAssumeValid(sfa, options.title);
        defer sfa.free(title);
        const width, const height = window.size + window.wra;
        window.hwnd = null; // will be read inside call below
        window.hwnd = CreateWindowExW(
            window.ex_style,
            atomCast(window.class_atom),
            title.ptr,
            window.style,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            width,
            height,
            null,
            null,
            imageBase(),
            null,
        ) orelse {
            // TODO: It can be other errors like returned from WM_{NC}CREATE (by us) and so on, of course.
            return error.SystemResources;
        };

        // needs an active hwnd to set these
        window.refreshCloseButton();
        if (global.win11_21h2_or_later) {
            assert(DwmSetWindowAttribute(window.hwnd.?, DWMWA_USE_IMMERSIVE_DARK_MODE, &TRUE, @sizeOf(BOOL)) == S_OK);
            setWindowCornerPreference(window.hwnd.?, @intFromEnum(options.win32_corner_rounding));
        }

        // belt and suspenders: let's get the default monitor (again)
        // on my machine CW_USEDEFAULT always goes to the primary, but...
        {
            const dpi = monitorDpi(MonitorFromWindow(window.hwnd.?, MONITOR_DEFAULTTOPRIMARY).?);
            if (dpi != window.dpi) {
                window.dpi = dpi;
                window.recalculateWindowRectangleAdjustment();
                width, height = window.size + window.wra;
                assert(SetWindowPos(window.hwnd.?, null, 0, 0, width, height, SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOZORDER) != 0);
            }
        }

        if (__flags.multi_window) {
            // increment window class reference count
            _ = SetClassLongPtrW(window.hwnd.?, 0, GetClassLongPtrW(window.hwnd.?, 0) + 1);
        }

        // ready to go! (do this at the end)
        assert(ShowWindow(window.hwnd.?, SW_SHOW) == 0);
    }

    pub fn deinit(window: *Window) void {
        var unregister_class = !__flags.multi_window;

        // decrement window class reference count, remove from linked list
        if (__flags.multi_window) {
            if (SetClassLongPtrW(window.hwnd.?, 0, GetClassLongPtrW(window.hwnd.?, 0) - 1) == 0) {
                unregister_class = true;
            }
        }

        // the window needs to exist for the above calls so we awkwardly destroy it in the middle
        assert(DestroyWindow(window.hwnd.?) != 0);

        // this needs to be done once the window no longer exists to prevent windowFromHwnd crash
        if (__flags.multi_window) {
            window.removeFromLinkedList();
        }

        // unregister if reference count hits 0 (or if !multi_window)
        if (unregister_class) {
            assert(UnregisterClassW(atomCast(window.class_atom), imageBase()) != 0);
        }
    }

    fn recalculateWindowRectangleAdjustment(window: *Window) void {
        var rect = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
        assert(AdjustWindowRectExForDpi(&rect, window.style, FALSE, window.ex_style, window.dpi) != 0);
        window.wra = .{ @intCast(rect.right - rect.left), @intCast(rect.bottom - rect.top) };
    }

    fn recalculateWindowStyle(window: *Window) void {
        window.style = WS_OVERLAPPED;
        window.ex_style = 0;
        if (window.controls.border) {
            window.style |= WS_CAPTION | WS_SYSMENU;
        } else {
            window.style |= WS_POPUP;
        }
        if (window.controls.minimise) {
            window.style |= WS_MINIMIZEBOX;
        }
        if (window.controls.maximise) {
            window.style |= WS_MAXIMIZEBOX;
        }
        if (window.controls.resize) {
            window.style |= WS_THICKFRAME;
        }
    }

    fn refreshCloseButton(window: *const Window) void {
        if (!window.controls.border) return;
        const state = if (window.controls.close) MF_ENABLED else MF_DISABLED | MF_GRAYED;
        _ = EnableMenuItem(GetSystemMenu(window.hwnd.?, FALSE).?, SC_CLOSE, MF_BYCOMMAND | state);
    }

    fn removeFromLinkedList(window: *Window) void {
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
};

// -- utility functions --

const atomCast = makeIntResource;

fn loadSystemCursor(cursor: wth.Cursor) HCURSOR {
    return @ptrCast(LoadImageW(null, makeIntResource(switch (cursor) {
        .Arrow => IDC_ARROW,
        .Busy => IDC_WAIT,
        .Cross => IDC_CROSS,
        .Hand => IDC_HAND,
        .IBeam => IDC_IBEAM,
        .Move => IDC_SIZEALL,
        .SizeNESW => IDC_SIZENESW,
        .SizeNS => IDC_SIZENS,
        .SizeNWSE => IDC_SIZENWSE,
        .SizeWE => IDC_SIZEWE,
        .Working => IDC_APPSTARTING,
    }), IMAGE_CURSOR, 0, 0, LR_DEFAULTSIZE | LR_SHARED).?);
}

inline fn makeIntResource(x: u16) [*:0]const u16 {
    @setRuntimeSafety(false);
    return @ptrFromInt(x);
}

fn monitorDpi(hmonitor: HMONITOR) u32 {
    var xdpi: u32, var ydpi: u32 = .{ undefined, undefined };
    assert(GetDpiForMonitor(hmonitor, MDT_EFFECTIVE_DPI, &xdpi, &ydpi) == S_OK);
    return xdpi;
}

fn osMouseEvent(hwnd: HWND, lparam: LPARAM, button: wth.MouseButton, what: enum { down, up }) std.mem.Allocator.Error!LRESULT {
    const window = windowFromHwnd(hwnd);
    const dword: u32 = @truncate(@as(usize, @bitCast(lparam)));
    const position = @Vector(2, wth.Window.Coordinate){
        @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword)))), 0, window.size[0])),
        @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword >> 16)))), 0, window.size[1])),
    };
    window.mouse_position = position;
    const payload = wth.Event.MouseClick{ .button = button, .position = position, .window = ww(window) };
    try pushEvent(switch (what) {
        .down => .{ .mouse_button_press_os = payload },
        .up => .{ .mouse_button_release_os = payload },
    });
    return 0;
}

// TODO: Would inlining this be better to not copy the Event?
fn pushEvent(event: wth.Event) std.mem.Allocator.Error!void {
    try global.event_buffer.append(global.allocator, event);
}

inline fn setWindowCornerPreference(hwnd: HWND, x: i32) void {
    assert(DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &x, @sizeOf(i32)) == S_OK);
}

inline fn utf8ToUtf16LeWithNullAssumeValid(allocator: std.mem.Allocator, utf8: []const u8) std.mem.Allocator.Error![:0]u16 {
    return std.unicode.utf8ToUtf16LeWithNull(allocator, utf8) catch |err| switch (err) {
        error.InvalidUtf8 => unreachable,
        error.OutOfMemory => return error.OutOfMemory,
    };
}

inline fn windowFromHwnd(hwnd: HWND) *Window {
    var head = global.window_head;
    if (__flags.multi_window) {
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

inline fn ww(window: *Window) if (__flags.multi_window) *wth.Window else void {
    if (__flags.multi_window) {
        return @fieldParentPtr(wth.Window, "impl", window);
    }
}

// -- windowproc and friends --

const fiber_proc_stack_size = 1024; // TODO: probably drop this
const fiber_timer_id = 1;

fn fiberProc(_: ?*anyopaque) callconv(WINAPI) void {
    while (true) {
        drainMessageQueue();
        SwitchToFiber(global.main_thread_fiber);
    }
}

fn drainMessageQueue() void {
    var msg: MSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        if (__flags.text_input) {
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

noinline fn windowProc(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(WINAPI) LRESULT {
    return windowProcMeta(hwnd, message, wparam, lparam) catch |err| {
        global.window_proc_error = err;
        return 0;
    };
}

fn windowProcMeta(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) std.mem.Allocator.Error!LRESULT {
    switch (message) {
        // magic spell to have fibers allow us to size/move without blocking sync()
        // TODO: explain what and how ^^^^^^^??? (i dont feel like it rn)
        WM_ENTERSIZEMOVE => {
            if (__flags.win32_fibers) {
                assert(SetTimer(hwnd, fiber_timer_id, 1, null) != 0);
            }
            return 0;
        },
        WM_EXITSIZEMOVE => {
            if (__flags.win32_fibers) {
                assert(KillTimer(hwnd, fiber_timer_id) != 0);
            }
            return 0;
        },
        WM_TIMER => {
            if (__flags.win32_fibers and wparam == fiber_timer_id) {
                SwitchToFiber(global.main_thread_fiber);
            }
            return 0;
        },

        WM_NCCREATE => {
            // enable per-monitor dpi awareness v1
            if (!global.win10_1703_or_later) {
                assert(EnableNonClientDpiScaling(hwnd) != 0);
            }
            return DefWindowProcW(hwnd, message, wparam, lparam);
        },

        WM_CLOSE => {
            try pushEvent(.{ .close_request = ww(windowFromHwnd(hwnd)) });
            return 0;
        },

        WM_PAINT => {
            // the system will flood the queue with this message until we acquire the hdc to calm it down
            // it doesn't matter if absolutely nothing is done, you need to do this or it will not stop
            var paintstruct: PAINTSTRUCT = undefined;
            assert(BeginPaint(hwnd, &paintstruct) != null);
            assert(EndPaint(hwnd, &paintstruct) != 0);
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
            try pushEvent(.{ .focus = ww(windowFromHwnd(hwnd)) });
            return 0;
        },
        WM_KILLFOCUS => {
            try pushEvent(.{ .unfocus = ww(windowFromHwnd(hwnd)) });
            return 0;
        },

        WM_SETCURSOR => {
            const hit_test: u16 = @truncate(@as(usize, @bitCast(lparam)));
            if (wparam == @intFromPtr(hwnd) and hit_test == HTCLIENT) {
                _ = SetCursor(windowFromHwnd(hwnd).cursor);
                return TRUE;
            } else {
                return DefWindowProcW(hwnd, message, wparam, lparam);
            }
        },

        WM_MOUSELEAVE => {
            const window = windowFromHwnd(hwnd);
            window.mouse_in_client_area = false;
            try pushEvent(.{ .mouse_leave = .{ .position = window.mouse_position, .window = ww(window) } });
            return 0;
        },
        WM_MOUSEMOVE => {
            // getting mouse coordinates outside of the client area is possible with some window styles, even if it shouldn't do that, so clamp it
            // things like the drop shadow count as part of the window rectangle and can sometimes send messages if it feels like, it's not documented
            const window = windowFromHwnd(hwnd);
            const dword: u32 = @truncate(@as(usize, @bitCast(lparam)));
            const position = @Vector(2, wth.Window.Coordinate){
                @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword)))), 0, window.size[0])),
                @intCast(std.math.clamp(@as(i16, @bitCast(@as(u16, @truncate(dword >> 16)))), 0, window.size[1])),
            };
            if (!window.mouse_in_client_area) {
                // the mouse entered just now (there's no WM_MOUSEENTER)
                try pushEvent(.{ .mouse_enter = .{ .position = position, .window = ww(window) } });
                // begin tracking WM_MOUSELEAVE message
                window.mouse_in_client_area = true;
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
                try pushEvent(.{ .mouse_move_os = .{ .position = window.mouse_position, .window = ww(window) } });
            }
            return 0;
        },

        WM_LBUTTONDOWN => return try osMouseEvent(hwnd, lparam, .left, .down),
        WM_LBUTTONUP => return try osMouseEvent(hwnd, lparam, .left, .up),
        WM_RBUTTONDOWN => return try osMouseEvent(hwnd, lparam, .right, .down),
        WM_RBUTTONUP => return try osMouseEvent(hwnd, lparam, .right, .up),
        WM_MBUTTONDOWN => return try osMouseEvent(hwnd, lparam, .middle, .down),
        WM_MBUTTONUP => return try osMouseEvent(hwnd, lparam, .middle, .up),
        WM_XBUTTONDOWN, WM_XBUTTONUP => return try osMouseEvent(
            hwnd,
            lparam,
            switch ((wparam >> 16) & 0xFFFF) {
                1 => wth.MouseButton.x1,
                2 => wth.MouseButton.x2,
                else => return 0, // nonsense
            },
            if (message == WM_XBUTTONDOWN) .down else .up,
        ),

        WM_GETMINMAXINFO => {
            const window = windowFromHwnd(hwnd);
            const mmi: *MINMAXINFO = @ptrFromInt(@as(usize, @bitCast(lparam)));
            mmi.ptMinTrackSize = .{ .x = 1 + window.wra[0], .y = 1 + window.wra[1] };
            return 0;
        },
        WM_SIZE => {
            const window = windowFromHwnd(hwnd);
            const xy: u32 = @truncate(@as(usize, @bitCast(lparam)));
            window.size = .{ @truncate(xy), @truncate(xy >> 16) };
            return 0;
        },
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

        WM_DPICHANGED => {
            const window = windowFromHwnd(hwnd);
            window.dpi = @truncate(wparam & 0xFFFF); // LOWORD is X DPI
            window.recalculateWindowRectangleAdjustment();
            const width, const height = window.size + window.wra;
            const suggestion_rect: *const RECT = @ptrFromInt(@as(usize, @bitCast(lparam)));
            assert(SetWindowPos(
                window.hwnd.?,
                null,
                suggestion_rect.left,
                suggestion_rect.top,
                width,
                height,
                SWP_NOACTIVATE | SWP_NOZORDER,
            ) != 0);
            return 0;
        },

        else => return DefWindowProcW(hwnd, message, wparam, lparam),
    }
}
