import Foundation

/// What the touch layout editor reads and writes (patch 0098): the arrangement, the size, the stick's place, the
/// 2D/3D layout and the icons. The library's editor uses the shared shell store; the in-game editor (the gear
/// menu's "Move buttons…") uses one game's store, and the model cannot tell the difference.
///
/// The editor model only ever talks to this protocol, so a per-game store needs no other change to the editor.
/// The 2D/3D layout is the one value that is not per game: the engine keeps that pick in the shared standard
/// defaults (DmPadLayout), so it is one choice for every game in the shell. A per-game store therefore reads and
/// writes the shared shell store for `touchMode`, and the editor's layout row behaves exactly as the library
/// editor's does. The icons are per game only: the shared store has no skin, so the protocol's default is "auto".
public protocol TouchLayoutStore: AnyObject {
    var touchLayout: TouchLayout { get }
    var touchSize: String { get }
    var touchStick: String { get }
    var touchMode: String { get }
    var touchSkin: String { get }
    func storeTouchSize(_ size: String)
    func storeTouchStick(_ place: String)
    func storeTouchLayout(_ layout: TouchLayout)
    func storeTouchMode(_ mode: String)
    func storeTouchSkin(_ skin: String)
}

public extension TouchLayoutStore {
    /// No shell-wide skin: a game without its own choice uses its folder when it has one (DM_TOUCH_SKIN=auto).
    var touchSkin: String { "auto" }
    /// The shared store keeps no per-game skin choice.
    func storeTouchSkin(_ skin: String) {}
}

/// The shared shell store is a layout store as it stands: every property and method above already exists on it
/// with these exact signatures (ShellSettingsStore).
extension ShellSettingsStore: TouchLayoutStore {}
