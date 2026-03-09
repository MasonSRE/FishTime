import Foundation

final class DailyRecordRepository {
    private let database: Database
    private var records: [DailyRecord]

    static func inMemory() throws -> DailyRecordRepository {
        try DailyRecordRepository(database: .inMemory())
    }

    init(database: Database) throws {
        self.database = database
        self.records = []
        try load()
    }

    func save(_ record: DailyRecord) throws {
        records.append(record)
        records.sort { $0.date < $1.date }
        try persist()
    }

    func fetchLatest() throws -> DailyRecord? {
        records.last
    }

    func fetchRecent(limit: Int = 30) throws -> [DailyRecord] {
        Array(records.suffix(limit)).reversed()
    }

    func reset() throws {
        records.removeAll()
        if let fileURL = database.fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func load() throws {
        guard let fileURL = database.fileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        records = try decoder.decode([DailyRecord].self, from: data)
    }

    private func persist() throws {
        guard let fileURL = database.fileURL else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(records)
        try data.write(to: fileURL, options: .atomic)
    }
}
