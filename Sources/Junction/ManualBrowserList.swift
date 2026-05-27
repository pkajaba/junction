import Foundation
import AppKit
import Combine

/// Browsers the user adds by hand from the Browsers tab's empty-state
/// card, when Launch Services' `http`-handler scan doesn't pick them up.
/// Stored in `UserDefaults` as a JSON-encoded array under
/// `JunctionManualBrowsers`.
///
/// Different from `BrowserExtraList`: that one is for *already-detected
/// `http`-handler apps* the user wants to promote into the picker.
/// This one is for apps that don't register as http handlers at all
/// (e.g. some Chromium forks that never reached LaunchServices, or
/// browsers installed outside /Applications). Same end result — they
/// show up in the picker — but the data model carries a user-provided
/// display name and an optional icon path because the resolution
/// path may not have those.
@MainActor
final class ManualBrowserList: ObservableObject {

    struct Entry: Codable, Equatable, Identifiable {
        let bundleID: String
        var displayName: String
        var iconPath: String?
        var id: String { bundleID }
    }

    static let shared = ManualBrowserList()

    private static let defaultsKey = "JunctionManualBrowsers"

    @Published private(set) var entries: [Entry] = []

    private init() {
        load()
    }

    func add(bundleID: String, displayName: String, iconPath: String? = nil) {
        let cleaned = bundleID.trimmingCharacters(in: .whitespaces)
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, !name.isEmpty else { return }
        // Replace if the bundle ID already exists — covers the
        // "I typed a duplicate" case without producing two rows.
        entries.removeAll { $0.bundleID == cleaned }
        entries.append(Entry(bundleID: cleaned, displayName: name, iconPath: iconPath))
        persist()
    }

    func remove(bundleID: String) {
        entries.removeAll { $0.bundleID == bundleID }
        persist()
    }

    /// Resolves a manual entry into a `DetectedBrowser` if the app is
    /// actually on disk. Manual entries that no longer resolve still
    /// live in the list (so the user can remove them) but they aren't
    /// included in `detectAll()` results — nothing to route to.
    func resolvedBrowser(for entry: Entry) -> DetectedBrowser? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.bundleID) else {
            return nil
        }
        return DetectedBrowser(
            bundleID: entry.bundleID,
            displayName: entry.displayName,
            appURL: url
        )
    }

    /// Returns every manual entry that currently resolves on disk, as a
    /// `[DetectedBrowser]` ready to be unioned into detection results.
    func resolvedBrowsers() -> [DetectedBrowser] {
        entries.compactMap(resolvedBrowser)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = decoded
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
