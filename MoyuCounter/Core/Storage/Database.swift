import Foundation

struct Database {
    let fileURL: URL?

    static func inMemory() -> Database {
        Database(fileURL: nil)
    }
}
