import SwiftUI

struct MainWindowView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var menuBarViewModel: MenuBarViewModel
    @ObservedObject var reportViewModel: TodayReportViewModel
    @ObservedObject var permissionViewModel: PermissionOnboardingViewModel
    let registerMainWindowOpener: (@escaping () -> Void) -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppStrings.App.name)
                    .font(.title2.bold())
                Text("\(AppStrings.MenuBar.statusLabel)：\(menuBarViewModel.statusText)")
                Text("\(AppStrings.MenuBar.todayEventsLabel)：\(menuBarViewModel.todayEventCount)")
                    .foregroundStyle(.secondary)
            }

            TodayReportView(
                presentation: reportViewModel.presentation,
                periodPresentation: reportViewModel.periodPresentation,
                selectedSurface: reportViewModel.selectedSurface,
                selectedPeriodScope: reportViewModel.selectedPeriodScope,
                selectedTemplate: reportViewModel.selectedTemplate,
                onSelectSurface: reportViewModel.selectSurface,
                onSelectPeriodScope: reportViewModel.selectPeriodScope,
                onSelectTemplate: reportViewModel.selectTemplate,
                onRefreshVerdict: reportViewModel.refreshVerdict,
                onCopy: reportViewModel.copyCurrentReportToClipboard,
                onSave: reportViewModel.saveCurrentReport
            )

            Divider()

            PermissionOnboardingView(viewModel: permissionViewModel)

            HStack(spacing: 12) {
                Button(AppStrings.MenuBar.startTracking) {
                    menuBarViewModel.startTracking()
                    permissionViewModel.refreshStatus()
                }
                .disabled(!permissionViewModel.canStartTracking)

                Button(AppStrings.MenuBar.stopTracking) {
                    menuBarViewModel.stopTracking()
                }
            }

            HStack(spacing: 12) {
                Button(AppStrings.MenuBar.openHistory) {
                    openWindow(id: "history-window")
                }

                Button(AppStrings.MenuBar.openSettings) {
                    openSettings()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 320)
        .onAppear {
            permissionViewModel.refreshStatus()
            reportViewModel.reload()
            registerMainWindowOpener {
                openWindow(id: "main-window")
            }
        }
    }
}
