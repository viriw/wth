// notes for myself here, i suppose
//
// eventually i will need to care for identical event behaviour across platforms
//
// == first order of business is mouse enter/leave/move etc ==
// when a window spawns under the mouse it gets WM_MOUSEMOVE on windows so we send Enter PLUS it gets a Move on the same coord
// when it leaves it gets a Move + Leave on same coord
// same with alt tabbing etc
// this happens EVEN if its not a move so it emits Enter+Move and Move+Leave with the same coords if you spam alt tab
// right now i don't emit move if it's the same coord as last time. maybe i should? see what X does and also just think about it
//
// == number two ==
// we don't get unfocus() on Window.deinit() i think that's fairly normal

pub const Window = struct {
    pub const ResizeDirection = enum {
        left,
        right,
        top,
        top_left,
        top_right,
        bottom,
        bottom_left,
        bottom_right,
    };
    pub const ResizeHook = *const fn (
        from: @Vector(2, Window.Coordinate),
        to: @Vector(2, Window.Coordinate),
        direction: Window.ResizeDirection,
    ) @Vector(2, Window.Coordinate);
};
