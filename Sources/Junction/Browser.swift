import AppKit

/// A browser the user can pick from. Detected at runtime via Launch
/// Services. Identified by bundle ID — that's the stable identifier
/// across reinstalls, renames, and version updates.
struct DetectedBrowser: Identifiable, Equatable, Hashable {

    let bundleID: String
    let displayName: String
    let appURL: URL

    var id: String { bundleID }

    /// Browser icon, loaded on demand from the app bundle.
    ///
    /// Each call hits Launch Services; the cost is small (cached internally)
    /// but we avoid storing `NSImage` in this value type so it stays cheaply
    /// `Equatable`/`Hashable`.
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
