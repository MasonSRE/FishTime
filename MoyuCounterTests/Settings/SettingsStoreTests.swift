import XCTest
@testable import MoyuCounter

final class SettingsStoreTests: XCTestCase {
    func test_default_scope_is_work_hours_only() {
        let store = SettingsStore(userDefaults: UserDefaults(suiteName: #function)!)
        XCTAssertEqual(store.scope, .workHoursOnly)
    }
}
