import Foundation

protocol TrackingWindowProviding {
    func epochMinuteRange(for date: Date) -> ClosedRange<Int>
}

struct SettingsTrackingWindowProvider: TrackingWindowProviding {
    private let settingsStore: SettingsStore
    private let calendar: Calendar

    init(settingsStore: SettingsStore, calendar: Calendar = .current) {
        self.settingsStore = settingsStore
        self.calendar = calendar
    }

    func epochMinuteRange(for date: Date) -> ClosedRange<Int> {
        let startOfDay = calendar.startOfDay(for: date)
        let startEpochMinute = Int(startOfDay.timeIntervalSince1970) / 60

        switch settingsStore.scope {
        case .wholeDay:
            return startEpochMinute...(startEpochMinute + 1_439)
        case .workHoursOnly:
            let startMinute = settingsStore.workStartMinutes
            let endMinute = settingsStore.workEndMinutes

            if endMinute > startMinute {
                return (startEpochMinute + startMinute)...(startEpochMinute + endMinute - 1)
            }

            // Cross-day shift: e.g. 22:00 - 06:00 should include the midnight crossover.
            return (startEpochMinute + startMinute)...(startEpochMinute + endMinute + 1_439)
        }
    }
}
