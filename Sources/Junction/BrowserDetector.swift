import AppKit
import Foundation

/// Finds browsers installed on this Mac.
///
/// We ask Launch Services for everything that claims `http`, then filter to
/// apps we recognize as actual browsers (by bundle ID). This avoids the
/// picker filling up with apps like Discord and Slack that register as
/// `http` handlers only so OAuth deep-links work.
///
/// "Recognized" = the built-in `knownBrowserBundleIDs` allowlist **plus**
/// anything the user promoted via `BrowserExtraList` (Settings → Browsers →
/// "Other apps"). That keeps non-browsers out by default while still
/// letting the user surface a real browser Junction doesn't know yet.
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

    /// All recognized browsers (allowlist ∪ user-promoted), ignoring the
    /// hide list. Used by the Browsers settings tab and the rule editor's
    /// browser picker.
    func detectAll() -> [DetectedBrowser] {
        let recognized = recognizedBundleIDs()
        return rawHTTPHandlers()
            .filter { recognized.contains($0.bundleID) }
            .sorted(by: Self.browserSort)
    }

    /// `http`-handler apps that are **not** recognized as browsers —
    /// neither on the built-in allowlist nor user-promoted. Settings →
    /// Browsers surfaces these under "Other apps" so the user can promote
    /// a genuine browser Junction doesn't know about yet (issue #24).
    func detectUnrecognized() -> [DetectedBrowser] {
        let recognized = recognizedBundleIDs()
        return rawHTTPHandlers()
            .filter { !recognized.contains($0.bundleID) }
            .sorted(by: Self.browserSort)
    }

    // MARK: - Private

    /// Allowlist plus anything the user promoted via `BrowserExtraList`.
    private func recognizedBundleIDs() -> Set<String> {
        Self.knownBrowserBundleIDs.union(BrowserExtraList.shared.enabled)
    }

    /// Every `http`-handler app on this Mac, deduped, excluding Junction
    /// itself (listing ourselves would create an open-URL loop). No
    /// allowlist filter — callers pick the subset they want.
    private func rawHTTPHandlers() -> [DetectedBrowser] {
        guard let probe = URL(string: "https://example.com") else { return [] }

        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: probe)
        var seen: Set<String> = []
        var result: [DetectedBrowser] = []

        for appURL in appURLs {
            guard
                let bundle = Bundle(url: appURL),
                let bundleID = bundle.bundleIdentifier
            else { continue }

            if bundleID == "com.pkajaba.junction" { continue }
            guard !seen.contains(bundleID) else { continue }   // dedupe
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
        return result
    }

    /// Sort: Safari first (macOS default, likely "personal" target),
    /// then case-insensitive alphabetical.
    private static func browserSort(_ lhs: DetectedBrowser, _ rhs: DetectedBrowser) -> Bool {
        if lhs.bundleID == "com.apple.Safari" { return true }
        if rhs.bundleID == "com.apple.Safari" { return false }
        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }
}
