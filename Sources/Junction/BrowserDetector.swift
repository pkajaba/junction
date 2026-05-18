import AppKit
import Foundation

/// Finds browsers installed on this Mac.
///
/// We ask Launch Services for everything that claims `http`, then filter to
/// apps we recognize as actual browsers (by bundle ID). This avoids the
/// picker filling up with apps like Discord and Slack that register as
/// `http` handlers only so OAuth deep-links work.
///
/// The allowlist lives here for now. Settings (M5) will let the user toggle
/// unrecognized apps in, and toggle recognized ones out.
@MainActor
final class BrowserDetector {

    static let shared = BrowserDetector()
    private init() {}

    /// Bundle IDs we know to be browsers. Conservatively maintained — when
    /// in doubt, leave a browser out and let the user enable it from
    /// Settings rather than risk polluting the picker.
    static let knownBrowserBundleIDs: Set<String> = [
        // Safari and WebKit-based
        "com.apple.Safari",
        // Chromium family
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.google.Chrome.dev",
        "com.google.Chrome.beta",
        "com.brave.Browser",
        "com.brave.Browser.dev",
        "com.brave.Browser.beta",
        "com.brave.Browser.nightly",
        "com.microsoft.edgemac",
        "com.microsoft.edgemac.Beta",
        "com.microsoft.edgemac.Dev",
        "com.microsoft.edgemac.Canary",
        "com.operasoftware.Opera",
        "com.operasoftware.OperaDeveloper",
        "com.operasoftware.OperaNext",
        "com.operasoftware.OperaGX",
        "com.vivaldi.Vivaldi",
        "company.thebrowser.Browser",        // Arc
        "company.thebrowser.dia",            // Dia
        // Firefox / Gecko family
        "org.mozilla.firefox",
        "org.mozilla.firefoxdeveloperedition",
        "org.mozilla.nightly",
        "org.mozilla.LibreWolf",
        "io.gitlab.librewolf-community",
        "net.waterfox.waterfox",
        "io.tor.browser",
        // Other
        "app.zen-browser.zen",
        "org.qutebrowser.qutebrowser",
        "com.duckduckgo.macos.browser",
    ]

    /// Returns recognized browsers installed on this Mac, sorted with Safari
    /// first (it's the macOS default and the most likely "personal" target),
    /// then alphabetically. Excludes browsers the user has hidden via
    /// `BrowserHideList` (Settings → Browsers tab).
    func detect() -> [DetectedBrowser] {
        detectAll().filter { !BrowserHideList.shared.isHidden($0.bundleID) }
    }

    /// All recognized browsers, ignoring the hide list. Used by the
    /// Browsers settings tab to show *everything* with toggles, and by
    /// the rule editor's browser picker (a rule can target a hidden
    /// browser — we just won't surface it in the picker UI).
    func detectAll() -> [DetectedBrowser] {
        // Probe URL: any http URL works — we just want the list of registered handlers.
        guard let probe = URL(string: "https://example.com") else { return [] }

        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: probe)
        var seen: Set<String> = []
        var result: [DetectedBrowser] = []

        for appURL in appURLs {
            guard
                let bundle = Bundle(url: appURL),
                let bundleID = bundle.bundleIdentifier
            else { continue }

            // Never list ourselves — would cause an open-URL loop.
            if bundleID == "com.pkajaba.junction" { continue }
            // Allowlist: only recognized browsers.
            guard Self.knownBrowserBundleIDs.contains(bundleID) else { continue }
            // Dedupe (Launch Services occasionally returns duplicate paths).
            guard !seen.contains(bundleID) else { continue }
            seen.insert(bundleID)

            let name = FileManager.default
                .displayName(atPath: appURL.path)
                .replacingOccurrences(of: ".app", with: "")

            result.append(DetectedBrowser(
                bundleID: bundleID,
                displayName: name,
                appURL: appURL
            ))
        }

        return result.sorted { a, b in
            if a.bundleID == "com.apple.Safari" { return true }
            if b.bundleID == "com.apple.Safari" { return false }
            return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
        }
    }
}
