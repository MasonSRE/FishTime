import XCTest
@testable import MoyuCounter

final class SettingsStoreTests: XCTestCase {
    func test_default_scope_is_work_hours_only() {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: #function)!)
        XCTAssertEqual(store.scope, .workHoursOnly)
    }

    func test_selected_report_template_defaults_to_standard_and_persists() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(store.selectedReportTemplate, .standard)

        store.selectedReportTemplate = .certificate

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.selectedReportTemplate, .certificate)
    }

    func test_report_surface_and_period_scope_default_and_persist() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(store.selectedReportSurface, .daily)
        XCTAssertEqual(store.selectedPeriodScope, .current)

        store.selectedReportSurface = .monthly
        store.selectedPeriodScope = .previousCompleted

        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.selectedReportSurface, .monthly)
        XCTAssertEqual(reloaded.selectedPeriodScope, .previousCompleted)
    }
}
