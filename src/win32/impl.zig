const builtin = @import("builtin");
const root = @import("root");
const std = @import("std");
const wth = @import("../wth.zig");
const zigwin32 = @import("zigwin32");

// zig fmt: off
const assert                                     = std.debug.assert;
const WINAPI                                     = std.os.windows.WINAPI;
const L                                          = std.unicode.utf8ToUtf16LeStringLiteral;
const HANDLE                                     = zigwin32.foundation.HANDLE;
const HINSTANCE                                  = zigwin32.foundation.HINSTANCE;
const HWND                                       = zigwin32.foundation.HWND;
const LPARAM                                     = zigwin32.foundation.LPARAM;
const LRESULT                                    = zigwin32.foundation.LRESULT;
const WPARAM                                     = zigwin32.foundation.WPARAM;
const CP_UTF8                                    = zigwin32.globalization.CP_UTF8;
const MB_PRECOMPOSED                             = zigwin32.globalization.MB_PRECOMPOSED;
const MultiByteToWideChar                        = zigwin32.globalization.MultiByteToWideChar;
const IMAGE_DOS_HEADER                           = zigwin32.system.system_services.IMAGE_DOS_HEADER;
const AdjustWindowRectExForDpi                   = zigwin32.ui.hi_dpi.AdjustWindowRectExForDpi;
const EnableNonClientDpiScaling                  = zigwin32.ui.hi_dpi.EnableNonClientDpiScaling;
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    = zigwin32.ui.hi_dpi.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE;
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = zigwin32.ui.hi_dpi.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;
const SetThreadDpiAwarenessContext               = zigwin32.ui.hi_dpi.SetThreadDpiAwarenessContext;
const DefWindowProcW                             = zigwin32.ui.windows_and_messaging.DefWindowProcW;
const RegisterClassExW                           = zigwin32.ui.windows_and_messaging.RegisterClassExW;
const UnregisterClassW                           = zigwin32.ui.windows_and_messaging.UnregisterClassW;
const WNDCLASSEXW                                = zigwin32.ui.windows_and_messaging.WNDCLASSEXW;
// zig fmt: on

// undocumented
extern "ntdll" fn RtlGetNtVersionNumbers(*u32, *u32, *u32) callconv(WINAPI) void;

const global = struct {
    var class_atom: u16 = undefined;
    var main_thread_id: u32 = undefined;

    // Windows 10 1703 (Build 15063; April 2017; Redstone / "Creators Update")
    var win10_1703_or_later: bool = undefined;
    // Windows 11 21H2 (Build 22000; October 2021; Sun Valley)
    var win11_21h2_or_later: bool = undefined;
};

inline fn getCurrentThreadId() u32 {
    return switch (builtin.target.cpu.arch) {
        .x86 => asm (
            \\ movl %%fs:0x24, %[id]
            : [id] "=r" (-> u32),
        ),
        .x86_64 => @truncate(asm (
            \\ movq %%gs:0x48, %[id]
            : [id] "=r" (-> u64),
        )),
        else => @compileError("unsupported arch"),
    };
}

// fn utf8ToWstrAlloc(
//     allocator: std.mem.Allocator,
//     utf8: []const u8,
// ) std.mem.Allocator.Error![:0]const u16 {
//     if (utf8.len == 0) {
//         return &.{};
//     }
//     const wstr_len = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8.ptr, @intCast(utf8.len), null, 0);
//     const wstr_alloc = try allocator.allocSentinel(u16, @intCast(wstr_len), 0);
//     errdefer allocator.free(wstr_alloc);
//     _ = MultiByteToWideChar(CP_UTF8, MB_PRECOMPOSED, utf8.ptr, @intCast(utf8.len), wstr_alloc.ptr, wstr_len);
//     wstr_alloc[@intCast(wstr_len)] = 0; // write sentinel
//     return wstr_alloc;
// }

extern const __ImageBase: IMAGE_DOS_HEADER;
inline fn imageBase() HINSTANCE {
    return @ptrCast(&__ImageBase);
}

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

    // create global window class
    const class_name = if (@hasDecl(root, "wth_class_name"))
        L(root.wth_class_name)
    else
        L("wth");
    const wcex = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = @enumFromInt(0),
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = imageBase(),
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        // TODO: I don't think all class names are allowed? Some pre-registered ones?
        .lpszClassName = class_name.ptr,
        .hIconSm = null,
    };
    global.class_atom = RegisterClassExW(&wcex);
    if (global.class_atom == 0) {
        return error.SystemResources;
    }

    // store this for later (probably only useful for debug checks)
    global.main_thread_id = getCurrentThreadId();
}

pub fn deinit() void {
    const class_atom: [*:0]const u16 = blk: {
        @setRuntimeSafety(false);
        break :blk @ptrFromInt(global.class_atom);
    };
    assert(UnregisterClassW(class_atom, imageBase()) != 0);
}

fn windowProc(
    hwnd: HWND,
    message: u32,
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(WINAPI) LRESULT {
    return DefWindowProcW(hwnd, message, wparam, lparam);
}
