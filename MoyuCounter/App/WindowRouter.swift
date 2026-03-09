import AppKit
import Foundation

@MainActor
final class WindowRouter: ObservableObject {
    private var openMainWindowAction: (() -> Void)?

    func registerMainWindowOpener(_ action: @escaping () -> Void) {
        openMainWindowAction = action
    }

    func openMainWindow() {
        openMainWindowAction?()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
