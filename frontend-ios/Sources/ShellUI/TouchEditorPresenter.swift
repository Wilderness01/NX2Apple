#if os(iOS)
import SwiftUI
import UIKit

/// Presents the touch layout editor over a running game (patch 0098), from the gear menu's "Move buttons…" row:
/// GameMenu.swift posts `requestNotification` with the running game's title ID, and this presenter opens the
/// editor for that game. The engine cannot present SwiftUI itself, and the game view owns the window while a
/// game runs, so the editor is presented over the key window's root view controller, full-screen and landscape
/// on a phone, exactly as the library's editor presents itself (TouchEditorPresentation.Editor).
///
/// The editor edits ONE game's choices (the store `storeFor` builds for the title ID), never the shell-wide
/// ones: the library's editor keeps editing the shared store. The presenter lives for the app's life
/// (ShellApp.swift starts `shared` once): NotificationCenter does not retain its observer, so a local instance
/// would stop listening as soon as the library finished building.
///
/// Confirming saves through the store and then calls `onCommit` with the committed store, so the app can apply
/// the choices to the running game at once (dm_shell_touch_apply); cancelling saves nothing. Either way the
/// editor closes itself through the dismiss environment the hosting controller sets, and `onDismiss` only drops
/// the presenter's references.
@MainActor public final class TouchEditorPresenter {
    /// GameMenu.swift posts this with userInfo ["titleID": <the running game's title ID>].
    public static let requestNotification = Notification.Name("dev.nx2apple.shell.touchLayoutEditorRequested")

    public static let shared = TouchEditorPresenter()

    private var editor: TouchEditorPresentation.Editor?
    private var model: TouchLayoutEditorModel?
    private var storeFor: ((String) -> any TouchLayoutStore)?
    private var onCommit: ((any TouchLayoutStore) -> Void)?

    public init() {}

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Starts listening. `storeFor` builds the per-game store for the title ID in the notification; `onCommit`
    /// runs after the player confirms, with the committed store.
    public func start(storeFor: @escaping (String) -> any TouchLayoutStore, onCommit: @escaping (any TouchLayoutStore) -> Void) {
        self.storeFor = storeFor
        self.onCommit = onCommit
        NotificationCenter.default.addObserver(self, selector: #selector(requested(_:)), name: Self.requestNotification, object: nil)
    }

    @objc private func requested(_ note: Notification) {
        guard editor == nil else { return }   // one editor at a time; a second tap while it is open is ignored
        guard let titleID = note.userInfo?["titleID"] as? String, !titleID.isEmpty,
              let storeFor, let onCommit else { return }
        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow),
              let root = window.rootViewController else { return }
        let insets = window.safeAreaInsets
        let store = storeFor(titleID)
        let model = TouchLayoutEditorModel.forGame(window: window.bounds.size,
                                                   insets: EdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right),
                                                   store: store, titleID: titleID)
        self.model = model
        let editor = TouchEditorPresentation.Editor(rootView: AnyView(EmptyView()))
        editor.updateContent(AnyView(TouchLayoutEditorView(model: model, close: {
            model.commit()
            onCommit(store)
        }, cancel: {})))
        editor.onDismiss = { [weak self] in self?.editor = nil; self?.model = nil }
        editor.modalPresentationStyle = .fullScreen
        editor.isModalInPresentation = true
        self.editor = editor
        root.present(editor, animated: true)
    }
}
#endif
