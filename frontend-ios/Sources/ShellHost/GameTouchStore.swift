import Foundation
import ShellUI

/// One game's touch choices (patch 0098), in the per-game suite the engine's per-game settings already use
/// (dev.nx2apple.shell.game.<title ID>, GameDefaults.suitePrefix): the size, the stick's place, the arrangement
/// and the icons. Each is stored only when it differs from the default — a choice left alone follows the
/// shell-wide default instead of pinning this game — exactly as ShellSettingsStore stores its own values.
/// The shell overlays these over its own defaults at Play (ShellHostModel.launchEnvironment), so the order is
/// game > shell > built-in, and the engine's own save (DmGamepad.m dm_touch_choice_save) writes the same keys.
///
/// The 2D/3D layout is NOT per game: the engine keeps that pick in the shared standard defaults (DmPadLayout),
/// so it is one choice for every game in the shell, as today. `touchMode` therefore reads and writes the shared
/// shell store, and the editor's layout row behaves exactly as the library editor's does.
public final class GameTouchStore: TouchLayoutStore {
    /// auto (default) draws the game's own bundled art when it has any; off always draws the built-in icons.
    public static let touchSkinKey = "touchSkin"
    public static let touchSkins = ["auto", "off"]

    private let defaults: UserDefaults

    public init(titleID: String) {
        defaults = GameDefaults.suite(for: titleID)
    }

    public var touchSize: String {
        let value = defaults.string(forKey: ShellSettingsStore.touchSizeKey) ?? "medium"
        return ShellSettingsStore.touchSizes.contains(value) ? value : "medium"
    }
    public func storeTouchSize(_ size: String) {
        guard ShellSettingsStore.touchSizes.contains(size) else { return }
        if size == "medium" { defaults.removeObject(forKey: ShellSettingsStore.touchSizeKey) } else { defaults.set(size, forKey: ShellSettingsStore.touchSizeKey) }
    }

    public var touchStick: String {
        let value = defaults.string(forKey: ShellSettingsStore.touchStickKey) ?? "corner"
        return ShellSettingsStore.touchStickPlaces.contains(value) ? value : "corner"
    }
    public func storeTouchStick(_ place: String) {
        guard ShellSettingsStore.touchStickPlaces.contains(place) else { return }
        if place == "corner" { defaults.removeObject(forKey: ShellSettingsStore.touchStickKey) } else { defaults.set(place, forKey: ShellSettingsStore.touchStickKey) }
    }

    public var touchLayout: TouchLayout {
        defaults.string(forKey: ShellSettingsStore.touchLayoutKey).flatMap { TouchLayout(encoded: $0) } ?? TouchLayout()
    }
    public func storeTouchLayout(_ layout: TouchLayout) {
        if layout.isEmpty { defaults.removeObject(forKey: ShellSettingsStore.touchLayoutKey) } else { defaults.set(layout.encoded, forKey: ShellSettingsStore.touchLayoutKey) }
    }

    public var touchMode: String { ShellSettingsStore.current.touchMode }
    public func storeTouchMode(_ mode: String) { ShellSettingsStore.current.storeTouchMode(mode) }

    public var touchSkin: String {
        let value = defaults.string(forKey: Self.touchSkinKey) ?? "auto"
        return Self.touchSkins.contains(value) ? value : "auto"
    }
    public func storeTouchSkin(_ skin: String) {
        guard Self.touchSkins.contains(skin) else { return }
        if skin == "auto" { defaults.removeObject(forKey: Self.touchSkinKey) } else { defaults.set(skin, forKey: Self.touchSkinKey) }
    }

    /// The launch environment's values for this game: only the choices that differ from the defaults, so the
    /// shell's own defaults still fill in the rest (ShellHostModel.launchEnvironment overlays these last).
    public var environmentValues: [String: String] {
        var values: [String: String] = [:]
        if touchSize != "medium" { values["DM_TOUCH_SIZE"] = touchSize }
        if touchStick != "corner" { values["DM_TOUCH_STICK"] = touchStick }
        let layout = touchLayout.encoded
        if !layout.isEmpty { values["DM_TOUCH_LAYOUT"] = layout }
        if touchSkin != "auto" { values["DM_TOUCH_SKIN"] = touchSkin }
        return values
    }
}
