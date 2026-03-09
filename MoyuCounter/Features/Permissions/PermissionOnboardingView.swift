import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject var viewModel: PermissionOnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.message)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            Button(AppStrings.Permission.grantPermission) {
                viewModel.requestPermission()
            }
            .disabled(viewModel.canStartTracking)
        }
    }
}
