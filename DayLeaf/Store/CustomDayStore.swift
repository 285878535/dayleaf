import Foundation
import Combine

final class CustomDayStore: ObservableObject {
    @Published private(set) var rules: [CustomDayRule] = []
    private var lookup: [String: CustomDayRule] = [:]

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DayLeaf", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("CustomDays.json")
    }()

    init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CustomDayRule].self, from: data) else { return }
        rules = decoded
        rebuildLookup()
    }

    private func rebuildLookup() {
        lookup = Dictionary(uniqueKeysWithValues: rules.map { ($0.date, $0) })
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: fileURL)
    }

    func rule(forDateKey key: String) -> CustomDayRule? {
        lookup[key]
    }

    func setRule(dateKey: String, isWorkday: Bool) {
        rules.removeAll { $0.date == dateKey }
        rules.append(CustomDayRule(id: UUID().uuidString, date: dateKey, isWorkday: isWorkday))
        rebuildLookup()
        persist()
    }

    func removeRule(dateKey: String) {
        rules.removeAll { $0.date == dateKey }
        rebuildLookup()
        persist()
    }
}
