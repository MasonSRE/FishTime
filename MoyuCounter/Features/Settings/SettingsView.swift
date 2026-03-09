import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    var onResetData: (() -> Void)?

    var body: some View {
        Form {
            Picker(AppStrings.Settings.trackingScope, selection: $store.scope) {
                Text(AppStrings.Settings.workHoursOnly).tag(TrackingScope.workHoursOnly)
                Text(AppStrings.Settings.wholeDay).tag(TrackingScope.wholeDay)
            }

            Stepper("\(AppStrings.Settings.startMinute)：\(store.workStartMinutes)", value: $store.workStartMinutes, in: 0...1439)
            Stepper("\(AppStrings.Settings.endMinute)：\(store.workEndMinutes)", value: $store.workEndMinutes, in: 0...1439)

            Button(AppStrings.Settings.resetLocalData, role: .destructive) {
                onResetData?()
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
