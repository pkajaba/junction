import Foundation

/// Owns the rules list and its on-disk representation.
///
/// Storage: `~/Library/Application Support/Junction/rules.json`.
/// Atomic writes (`.write(to:options:.atomic)`) prevent half-written files
/// if the process dies mid-save. Reads are best-effort: a corrupt or
/// missing file leaves the in-memory state untouched (or empty on first
/// launch) and surfaces the error via `lastError` for the UI to display.
///
/// Live reload (file watching for external edits) is deferred to M5 along
/// with the Settings UI. For now, users can edit `rules.json` and pick
/// "Reload Rules" from the menu (⌥⌘R).
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

    // MARK: - Load / save

    /// Read rules from disk. Bootstraps an empty file on first launch so
    /// the user can find it.
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
            self.rules = file.rules
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

    /// Replace the entire rules list and persist. Used by the future
    /// settings UI; M4 callers don't need this yet.
    func replace(with newRules: [Rule]) {
        rules = newRules
        persist()
    }

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
