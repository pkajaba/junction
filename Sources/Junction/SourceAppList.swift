import AppKit
import Foundation

/// Enumerates apps the user might pick as a rule's `sourceApp` condition,
/// and resolves bundle IDs to human-readable names.
///
/// "Source app" = the app a link was opened *from*. The rule editor's
/// "From app" picker offers currently-running regular apps; a rule can
/// also reference an app that isn't running right now, so this type
/// resolves an arbitrary bundle ID to a display name on demand.
@MainActor
enum SourceAppList {

    /// One pickable app.
    struct App: Identifiable, Hashable {
        let bundleID: String
        let displayName: String
        var id: String { bundleID }
    }

    /// Currently-running regular (Dock-visible) apps, deduped by bundle
    /// ID, sorted by name. Junction itself is excluded — a link can't
    /// meaningfully originate from the router.
    static func runningApps() -> [App] {
        var seen: Set<String> = []
        var result: [App] = []
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  bundleID != "com.pkajaba.junction",
                  !seen.contains(bundleID)
            else { continue }
            seen.insert(bundleID)
            result.append(App(
                bundleID: bundleID,
                displayName: app.localizedName ?? displayName(for: bundleID)
            ))
        }
        return result.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    /// Human-readable name for a bundle ID, falling back to the bundle
    /// ID itself when the app can't be located on disk.
    static func displayName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }
}
