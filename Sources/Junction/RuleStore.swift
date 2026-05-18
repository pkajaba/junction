import Foundation

/// Owns the rules list and its on-disk representation.
///
/// Storage: `~/Library/Application Support/Junction/rules.json`.
/// Atomic writes (`.write(to:options:.atomic)`) prevent half-written files
/// if the process dies mid-save. Reads are best-effort: a corrupt or
/// missing file leaves the in-memory state untouched (or empty on first
/// launch) and surfaces the error via `lastError` for the UI to display.
///
/// Live reload: an `FSEventStream` on the parent directory triggers a
/// re-read when the file changes. We compare the decoded array against
/// in-memory state and only publish if it actually differs — that
/// suppresses the loop of "we wrote → watcher fires → we 'reload' the
/// same content → publish → views think rules changed".
@MainActor
final class RuleStore: ObservableObject {

    static let shared = RuleStore()

    /// On-disk wrapper, with a schema version for future migrations.
    struct File: Codable, Equatable {
        var schemaVersion: Int
        var rules: [Rule]

        init(rules: [Rule], schemaVersion: Int = 1) {
            self.schemaVersion = schemaVersion
            self.rules = rules
        }
    }

    @Published private(set) var rules: [Rule] = []
    /// Last load or save error, if any. UI surfaces this so the user knows
    /// when their edits aren't taking effect.
    @Published private(set) var lastError: String?

    private var fileWatcher: FileWatcher?

    private init() {}

    // MARK: - File location

    /// Where `rules.json` lives. Public so the menu can reveal it in Finder.
    static var storeURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let dir = appSupport.appendingPathComponent("Junction", isDirectory: true)
        return dir.appendingPathComponent("rules.json")
    }

    // MARK: - Lifecycle

    /// Load from disk and start watching for external edits.
    func startup() {
        load()
        startWatching()
    }

    private func startWatching() {
        guard fileWatcher == nil else { return }
        fileWatcher = FileWatcher(url: Self.storeURL) { [weak self] in
            // Hops to main via FileWatcher; safe to call @MainActor methods.
            Task { @MainActor in self?.load() }
        }
        fileWatcher?.start()
    }

    // MARK: - Load / save

    /// Read rules from disk. Bootstraps an empty file on first launch.
    /// No-op if the decoded content matches what we already have — avoids
    /// a feedback loop with the file watcher.
    func load() {
        let url = Self.storeURL

        // Ensure parent directory exists; harmless if it already does.
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard FileManager.default.fileExists(atPath: url.path) else {
            // First launch: write an empty rules file so the user knows where it is.
            self.rules = []
            self.lastError = nil
            persist()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(File.self, from: data)
            if file.rules != self.rules {
                self.rules = file.rules
            }
            self.lastError = nil
        } catch {
            self.lastError = "rules.json: \(error.localizedDescription)"
            // Keep whatever's in memory rather than blanking on a parse error.
        }
    }

    /// Persist current `rules` to disk atomically.
    func save() {
        persist()
    }

    // MARK: - CRUD

    func add(_ rule: Rule) {
        rules.append(rule)
        persist()
    }

    func update(_ rule: Rule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        persist()
    }

    func delete(id: UUID) {
        rules.removeAll { $0.id == id }
        persist()
    }

    /// Move rules by index set. Compatible with SwiftUI `List.onMove`.
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Replace the entire rules list and persist. Used by the future
    /// settings UI's "import" feature.
    func replace(with newRules: [Rule]) {
        rules = newRules
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let file = File(rules: rules, schemaVersion: 1)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(file)
            try data.write(to: Self.storeURL, options: .atomic)
            self.lastError = nil
        } catch {
            self.lastError = "Failed to write rules.json: \(error.localizedDescription)"
        }
    }
}
