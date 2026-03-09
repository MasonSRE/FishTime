import SwiftUI

struct MenuBarRootView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var viewModel: MenuBarViewModel
    @ObservedObject var reportViewModel: TodayReportViewModel
    @ObservedObject var permissionViewModel: PermissionOnboardingViewModel
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(AppStrings.MenuBar.statusLabel)：\(viewModel.statusText)")
            Text("\(AppStrings.MenuBar.todayEventsLabel)：\(viewModel.todayEventCount)")

            TodayReportView(
                presentation: reportViewModel.presentation,
                isCompact: true,
                onRefreshVerdict: reportViewModel.refreshVerdict,
                onCopy: viewModel.copyPosterToClipboard,
                onSave: viewModel.generatePosterAndSave
            )

            Divider()

            PermissionOnboardingView(viewModel: permissionViewModel)

            Button(AppStrings.MenuBar.startTracking) {
                viewModel.startTracking()
                permissionViewModel.refreshStatus()
            }
            .disabled(!permissionViewModel.canStartTracking)

            Button(AppStrings.MenuBar.stopTracking) {
                viewModel.stopTracking()
            }

            Button(AppStrings.MenuBar.openHistory) {
                openWindow(id: "history-window")
            }

            Button(AppStrings.MenuBar.openSettings) {
                openSettings()
            }
        }
        .padding(12)
        .frame(width: 260)
        .onAppear {
            permissionViewModel.refreshStatus()
            reportViewModel.reload()
        }
    }
}
