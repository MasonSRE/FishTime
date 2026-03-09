import AppKit
import SwiftUI

@main
struct MoyuCounterApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        Window(AppStrings.Window.main, id: "main-window") {
            MainWindowView(
                menuBarViewModel: dependencies.menuBarViewModel,
                reportViewModel: dependencies.todayReportViewModel,
                permissionViewModel: dependencies.permissionViewModel,
                registerMainWindowOpener: dependencies.windowRouter.registerMainWindowOpener,
                openSettings: openSettingsWindow
            )
        }
        .defaultSize(width: 560, height: 360)

        MenuBarExtra(AppStrings.App.name, systemImage: "fish") {
            MenuBarRootView(
                viewModel: dependencies.menuBarViewModel,
                reportViewModel: dependencies.todayReportViewModel,
                permissionViewModel: dependencies.permissionViewModel,
                openSettings: openSettingsWindow
            )
        }

        Window(AppStrings.Window.history, id: "history-window") {
            HistoryView(viewModel: dependencies.historyViewModel)
        }
        .defaultSize(width: 380, height: 460)

        Settings {
            SettingsView(store: dependencies.settingsStore) {
                dependencies.resetLocalData()
            }
        }
    }

    private func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
