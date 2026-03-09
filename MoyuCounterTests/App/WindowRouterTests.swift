import XCTest
@testable import MoyuCounter

@MainActor
final class WindowRouterTests: XCTestCase {
    func test_open_main_window_runs_registered_action() {
        let router = WindowRouter()
        var openCount = 0

        router.registerMainWindowOpener {
            openCount += 1
        }
        router.openMainWindow()

        XCTAssertEqual(openCount, 1)
    }
}
