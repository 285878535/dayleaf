import Foundation
import Combine

final class HistoryStore: ObservableObject {
    @Published private(set) var records: [HistoryRecord] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DayLeaf", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("History.json")
    }()

    init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([HistoryRecord].self, from: data) else { return }
        records = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL)
    }

    func add(_ record: HistoryRecord, limit: Int) {
        records.removeAll { $0.startDate == record.startDate && $0.endDate == record.endDate }
        records.insert(record, at: 0)
        if records.count > limit {
            records = Array(records.prefix(limit))
        }
        persist()
    }

    func remove(_ record: HistoryRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func clearAll() {
        records.removeAll()
        persist()
    }
}
