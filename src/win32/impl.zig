//! Win32 implementation. The minimum version is Windows 10 1607 (Build 14393; April 2016; Redstone / "Anniversary Update").

const root = @import("root");
const std = @import("std");
const wth = @import("../wth.zig");
const zigwin32 = @import("zigwin32");

// replace with actual build flags at some point. hardcoding now for testing
const __flags = struct {
    const multi_window: bool = true;
    const text_input: bool = false;
    const win32_fibers: bool = true;
};

// zig fmt: off
const assert                                     = std.debug.assert;
const WINAPI                                     = std.os.windows.WINAPI;
const L                                          = std.unicode.utf8ToUtf16LeStringLiteral;
const GetLastError                               = zigwin32.foundation.GetLastError;
const HANDLE                                     = zigwin32.foundation.HANDLE;
const HINSTANCE                                  = zigwin32.foundation.HINSTANCE;
const HRESULT                                    = zigwin32.foundation.HRESULT;
const HWND                                       = zigwin32.foundation.HWND;
const LPARAM                                     = zigwin32.foundation.LPARAM;
const LRESULT                                    = zigwin32.foundation.LRESULT;
const RECT                                       = zigwin32.foundation.RECT;
const S_OK                                       = zigwin32.foundation.S_OK;
const WPARAM                                     = zigwin32.foundation.WPARAM;
const HMONITOR                                   = zigwin32.graphics.gdi.HMONITOR;
const MONITOR_DEFAULTTONULL                      = zigwin32.graphics.gdi.MONITOR_DEFAULTTONULL;
const MonitorFromWindow                          = zigwin32.graphics.gdi.MonitorFromWindow;
const CP_UTF8                                    = zigwin32.globalization.CP_UTF8;
const MB_PRECOMPOSED                             = zigwin32.globalization.MB_PRECOMPOSED;
const MultiByteToWideChar                        = zigwin32.globalization.MultiByteToWideChar;
const IMAGE_DOS_HEADER                           = zigwin32.system.system_services.IMAGE_DOS_HEADER;
const CreateFiber                                = zigwin32.system.threading.CreateFiber;
const DeleteFiber                                = zigwin32.system.threading.DeleteFiber;
const ConvertFiberToThread                       = zigwin32.system.threading.ConvertFiberToThread;
const ConvertThreadToFiber                       = zigwin32.system.threading.ConvertThreadToFiber;
const SwitchToFiber                              = zigwin32.system.threading.SwitchToFiber;
const AdjustWindowRectExForDpi                   = zigwin32.ui.hi_dpi.AdjustWindowRectExForDpi;
const EnableNonClientDpiScaling                  = zigwin32.ui.hi_dpi.EnableNonClientDpiScaling;
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    = zigwin32.ui.hi_dpi.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE;
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = zigwin32.ui.hi_dpi.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;
const MDT_EFFECTIVE_DPI                          = zigwin32.ui.hi_dpi.MDT_EFFECTIVE_DPI;
const MONITOR_DPI_TYPE                           = zigwin32.ui.hi_dpi.MONITOR_DPI_TYPE;
const SetThreadDpiAwarenessContext               = zigwin32.ui.hi_dpi.SetThreadDpiAwarenessContext;
const CreateWindowExW                            = zigwin32.ui.windows_and_messaging.CreateWindowExW;
const CW_USEDEFAULT                              = zigwin32.ui.windows_and_messaging.CW_USEDEFAULT;
const DefWindowProcW                             = zigwin32.ui.windows_and_messaging.DefWindowProcW;
const DestroyWindow                              = zigwin32.ui.windows_and_messaging.DestroyWindow;
const DispatchMessageW                           = zigwin32.ui.windows_and_messaging.DispatchMessageW;
const GetClassInfoExW                            = zigwin32.ui.windows_and_messaging.GetClassInfoExW;
const KillTimer                                  = zigwin32.ui.windows_and_messaging.KillTimer;
const MSG                                        = zigwin32.ui.windows_and_messaging.MSG;
const PeekMessageW                               = zigwin32.ui.windows_and_messaging.PeekMessageW;
const PM_REMOVE                                  = zigwin32.ui.windows_and_messaging.PM_REMOVE;
const PostQuitMessage                            = zigwin32.ui.windows_and_messaging.PostQuitMessage;
const RegisterClassExW                           = zigwin32.ui.windows_and_messaging.RegisterClassExW;
const SetTimer                                   = zigwin32.ui.windows_and_messaging.SetTimer;
const SetWindowPos                               = zigwin32.ui.windows_and_messaging.SetWindowPos;
const ShowWindow                                 = zigwin32.ui.windows_and_messaging.ShowWindow;
const TranslateMessage                           = zigwin32.ui.windows_and_messaging.TranslateMessage;
const UnregisterClassW                           = zigwin32.ui.windows_and_messaging.UnregisterClassW;
const WINDOW_STYLE                               = zigwin32.ui.windows_and_messaging.WINDOW_STYLE;
const WM_CLOSE                                   = zigwin32.ui.windows_and_messaging.WM_CLOSE;
const WM_DPICHANGED                              = zigwin32.ui.windows_and_messaging.WM_DPICHANGED;
const WM_DESTROY                                 = zigwin32.ui.windows_and_messaging.WM_DESTROY;
const WM_ENTERSIZEMOVE                           = zigwin32.ui.windows_and_messaging.WM_ENTERSIZEMOVE;
const WM_EXITSIZEMOVE                            = zigwin32.ui.windows_and_messaging.WM_EXITSIZEMOVE;
const WM_NCCREATE                                = zigwin32.ui.windows_and_messaging.WM_NCCREATE;
const WM_TIMER                                   = zigwin32.ui.windows_and_messaging.WM_TIMER;
const WM_QUIT                                    = zigwin32.ui.windows_and_messaging.WM_QUIT;
const WNDCLASSEXW                                = zigwin32.ui.windows_and_messaging.WNDCLASSEXW;
const FALSE                                      = zigwin32.zig.FALSE;
// zig fmt: on

// The zigwin32 definitions for these functions use an obnoxious *exhaustive* enum for the offset.
// They're also completely missing the wrappers for the class storage wrappers and such.
const clwl = struct {
    const wrap = struct {
        pub extern "user32" fn GetClassLongW(hwnd: HWND, offset: i32) callconv(WINAPI) u32;
        pub extern "user32" fn GetClassLongPtrW(hWnd: HWND, offset: i32) callconv(WINAPI) usize;
        pub extern "user32" fn SetClassLongW(hwnd: HWND, offset: i32, value: u32) callconv(WINAPI) u32;
        pub extern "user32" fn SetClassLongPtrW(hwnd: HWND, offset: i32, value: usize) callconv(WINAPI) usize;
        pub extern "user32" fn GetWindowLongW(hwnd: HWND, offset: i32) callconv(WINAPI) u32;
        pub extern "user32" fn GetWindowLongPtrW(hwnd: HWND, offset: i32) callconv(WINAPI) usize;
        pub extern "user32" fn SetWindowLongW(hwnd: HWND, offset: i32, value: u32) callconv(WINAPI) u32;
        pub extern "user32" fn SetWindowLongPtrW(hwnd: HWND, offset: i32, value: usize) callconv(WINAPI) usize;
    };
    pub const GetClassLongPtrW = if (@sizeOf(usize) == 8) wrap.GetClassLongPtrW else wrap.GetClassLongW;
    pub const SetClassLongPtrW = if (@sizeOf(usize) == 8) wrap.SetClassLongPtrW else wrap.SetClassLongW;
    pub const GetWindowLongPtrW = if (@sizeOf(usize) == 8) wrap.GetWindowLongPtrW else wrap.GetWindowLongW;
    pub const SetWindowLongPtrW = if (@sizeOf(usize) == 8) wrap.SetWindowLongPtrW else wrap.SetWindowLongW;
};
const GetClassLongPtrW = clwl.GetClassLongPtrW;
const SetClassLongPtrW = clwl.SetClassLongPtrW;
const GetWindowLongPtrW = clwl.GetWindowLongPtrW;
const SetWindowLongPtrW = clwl.SetWindowLongPtrW;
const GWL_STYLE = -16;
const GWL_EXSTYLE = -20;

// Work around for error(link): DLL import library for -lapi-ms-win-shcore-scaling-l1-1-1 not found.
extern "shcore" fn GetDpiForMonitor(hmonitor: HMONITOR, dpiType: MONITOR_DPI_TYPE, dpiX: *u32, dpiY: *u32) HRESULT;

/// Undocumented NTDLL function because there's genuinely no other way to do this reliably.
/// - https://www.geoffchappell.com/studies/windows/win32/ntdll/api/ldrinit/getntversionnumbers.htm
/// - https://dennisbabkin.com/blog/?t=how-to-tell-the-real-version-of-windows-your-app-is-running-on
extern "ntdll" fn RtlGetNtVersionNumbers(*u32, *u32, *u32) callconv(WINAPI) void;

/// Current module's HINSTANCE exposed through a Microsoft linker pseudo-variable.
/// - https://devblogs.microsoft.com/oldnewthing/20041025-00/?p=37483
extern const __ImageBase: IMAGE_DOS_HEADER;
inline fn imageBase() HINSTANCE {
    return @ptrCast(&__ImageBase);
}

fn utf8ToWtf16Alloc(
    allocator: std.mem.Allocator,
    utf8: []const u8,
) std.mem.Allocator.Error![:0]const u16 {
    // TODO: if safe mode validate the utf8
    if (utf8.len == 0) {
        return &.{};
    }
    const wstr_len = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8.ptr, @intCast(utf8.len), null, 0);
    const wstr_alloc = try allocator.allocSentinel(u16, @intCast(wstr_len), 0);
    errdefer allocator.free(wstr_alloc);
    _ = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8.ptr, @intCast(utf8.len), wstr_alloc.ptr, wstr_len);
    wstr_alloc[@intCast(wstr_len)] = 0; // write sentinel
    return wstr_alloc;
}

const global = struct {
    /// Handle to the main thread as a fiber.
    var main_thread_fiber = if (__flags.win32_fibers) @as(*anyopaque, undefined) else void{};
    /// Handle to the message fiber.
    var message_fiber = if (__flags.win32_fibers) @as(*anyopaque, undefined) else void{};
    /// Whether WM_QUIT has been posted with any exit code.
    var quit_posted: bool = undefined;
    /// The single window or list of windows.
    var window_head: *Window = undefined;
    /// Whether we're at least on Windows 10 1703 (Build 15063; April 2017; Redstone / "Creators Update").
    var win10_1703_or_later: bool = undefined;
    /// Whether we're at least on Windows 11 21H2 (Build 22000; October 2021; Sun Valley).
    var win11_21h2_or_later: bool = undefined;
};

pub fn init(_: wth.InitOptions) wth.InitError!void {
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

    global.quit_posted = false;
}

pub fn deinit() void {
    if (__flags.win32_fibers) {
        SwitchToFiber(global.message_fiber);
        DeleteFiber(global.message_fiber);
        assert(ConvertFiberToThread() != 0);
    } else {
        drainMessageQueue();
    }
}

pub inline fn sync() wth.SyncError!void {
    if (__flags.win32_fibers) {
        SwitchToFiber(global.message_fiber);
    } else {
        drainMessageQueue();
    }
    if (global.quit_posted) {
        return error.Shutdown;
    }
}

pub const Window = struct {
    allocator: std.mem.Allocator,
    class_atom: u16,
    dpi: u32,
    hwnd: HWND,

    pub fn emplace(window: *Window, options: wth.Window.CreateOptions) wth.Window.CreateError!void {
        var sfa = std.heap.stackFallback(512, window.allocator);

        // check if the class exists, if not, register it
        window.class_atom, const class_created_here: bool = blk: {
            const allocator = sfa.get();
            const class_name = try utf8ToWtf16Alloc(allocator, options.class_name);
            defer allocator.free(class_name);

            // undocumented win32 tidbit: GetClassInfo** returns the class atom to act as the BOOL here
            // this is the only way to actually look up a class by its name as the atom table is private
            // - https://devblogs.microsoft.com/oldnewthing/20041011-00/?p=37603
            // - https://devblogs.microsoft.com/oldnewthing/20150429-00/?p=44984
            var wcex: WNDCLASSEXW = undefined;
            wcex.cbSize = @sizeOf(WNDCLASSEXW);
            var class_atom: u16 = if (__flags.multi_window) @intCast(GetClassInfoExW(imageBase(), class_name, &wcex)) else 0;
            var class_created_here = false;
            if (class_atom == 0) {
                // we can re-use the structure needed for GetClassInfoExW to actually register the window class
                wcex = .{
                    .cbSize = @sizeOf(WNDCLASSEXW),
                    .style = @enumFromInt(0),
                    .lpfnWndProc = windowProc,
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

        const allocator = sfa.get();
        const title = try utf8ToWtf16Alloc(allocator, options.title);
        defer allocator.free(title);
        window.hwnd = CreateWindowExW(
            @enumFromInt(0),
            atomCast(window.class_atom),
            title.ptr,
            WINDOW_STYLE.initFlags(.{ .POPUP = 1 }),
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            0,
            0,
            null,
            null,
            imageBase(),
            null,
        ) orelse {
            // TODO: It can be other errors like returned from WM_{NC}CREATE (by us) and so on, of course.
            return error.SystemResources;
        };

        window.dpi = 96;
        if (MonitorFromWindow(window.hwnd, MONITOR_DEFAULTTONULL)) |monitor| {
            var xdpi: u32, var ydpi: u32 = .{ undefined, undefined };
            assert(GetDpiForMonitor(monitor, MDT_EFFECTIVE_DPI, &xdpi, &ydpi) == S_OK);
            window.dpi = xdpi;
            std.debug.print("DPI from Monitor: {}\n", .{xdpi});
        }

        var width: u32, var height: u32 = adjustWindowRect(window.dpi, WINDOW_STYLE.initFlags(.{ .VISIBLE = 1, .THICKFRAME = 1, .CAPTION = 1, .SYSMENU = 1 }));
        width += 800;
        height += 608;
        _ = SetWindowLongPtrW(window.hwnd, GWL_STYLE, @intFromEnum(WINDOW_STYLE.initFlags(.{ .VISIBLE = 1, .THICKFRAME = 1, .CAPTION = 1, .SYSMENU = 1 })));
        assert(SetWindowPos(window.hwnd, null, 0, 0, @intCast(width), @intCast(height), .SHOWWINDOW) != 0);
        assert(ShowWindow(window.hwnd, .SHOW) != 0);

        if (__flags.multi_window) {
            _ = SetClassLongPtrW(window.hwnd, 0, GetClassLongPtrW(window.hwnd, 0) + 1);
        }
    }

    pub fn deinit(window: *Window) void {
        var unregister_class = !__flags.multi_window;
        if (__flags.multi_window) {
            if (SetClassLongPtrW(window.hwnd, 0, GetClassLongPtrW(window.hwnd, 0) - 1) == 0) {
                unregister_class = true;
            }
        }
        assert(DestroyWindow(window.hwnd) != 0);
        if (unregister_class) {
            assert(UnregisterClassW(atomCast(window.class_atom), imageBase()) != 0);
        }
    }
};

fn adjustWindowRect(dpi: u32, style: WINDOW_STYLE) struct { u32, u32 } {
    var rect = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    assert(AdjustWindowRectExForDpi(&rect, style, FALSE, @enumFromInt(0), dpi) != 0);
    return .{ @intCast(-rect.left + rect.right), @intCast(-rect.top + rect.bottom) };
}

inline fn atomCast(atom: u16) [*:0]const u16 {
    @setRuntimeSafety(false);
    return @ptrFromInt(atom);
}

fn drainMessageQueue() void {
    var msg: MSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        if (__flags.text_input) {
            _ = TranslateMessage(&msg);
        }
        if (msg.message != WM_QUIT) {
            _ = DispatchMessageW(&msg);
        } else {
            global.quit_posted = true;
        }
    }
}

const fiber_proc_stack_size = 1024;
const fiber_timer_id = 1;

fn fiberProc(_: ?*anyopaque) callconv(WINAPI) void {
    while (true) {
        drainMessageQueue();
        SwitchToFiber(global.main_thread_fiber);
    }
}

fn windowProc(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(WINAPI) LRESULT {
    switch (message) {
        // HACK: Until there's an event mechanism just treat the close button the same as task manager telling us to fuck off.
        WM_CLOSE => {
            PostQuitMessage(0);
            return 0;
        },
        WM_DESTROY => {
            return 0;
        },

        WM_NCCREATE => {
            // Per-Monitor DPI Awareness V1
            if (!global.win10_1703_or_later) {
                assert(EnableNonClientDpiScaling(hwnd) != 0);
            }
            return DefWindowProcW(hwnd, message, wparam, lparam);
        },

        WM_DPICHANGED => {
            const new_dpi: u16 = @truncate(wparam);
            const rect_suggestion: *const RECT = @ptrFromInt(@as(usize, @bitCast(lparam)));
            std.debug.print("DPI CHANGE!\n  -> New DPI: {}\n  -> Rect Suggestion: {}\n", .{ new_dpi, rect_suggestion });
            return 0;
        },

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

        else => return DefWindowProcW(hwnd, message, wparam, lparam),
    }
}
