import Foundation

/// Reads per-browser profile metadata so the rule editor can show real
/// profile names instead of asking the user to remember `"Default"`.
///
/// Two formats supported at M6:
/// - **Chromium** (`com.google.Chrome`, `com.brave.Browser`, etc.): the
///   `Local State` JSON file's `profile.info_cache` dictionary maps
///   profile **directory names** (which is what `--profile-directory=`
///   expects) to display names.
/// - **Firefox**: `profiles.ini` lists profiles with `Name=...` keys.
///   `-P <name>` selects one at launch.
struct ProfileDetector {

    /// A profile suitable for the rule editor's dropdown.
    struct ProfileInfo: Hashable, Identifiable {
        /// Stable identifier — directory name for Chromium, profile name
        /// for Firefox. This is the value we'd pass to the browser at
        /// launch time as `--profile-directory=` or `-P`.
        let id: String
        /// What the user sees in the browser's own profile switcher.
        let displayName: String
    }

    static func detect(forBundleID bundleID: String) -> [ProfileInfo] {
        if let folder = chromiumSupportFolder(forBundleID: bundleID) {
            return readChromiumLocalState(in: folder)
        }
        if bundleID == "org.mozilla.firefox"
            || bundleID == "org.mozilla.firefoxdeveloperedition"
            || bundleID == "org.mozilla.nightly" {
            return readFirefoxProfilesIni()
        }
        return []
    }

    // MARK: - Chromium

    /// Maps Chromium-family bundle IDs to their Application Support
    /// subfolder. Each Chromium browser stores `Local State` differently.
    private static func chromiumSupportFolder(forBundleID bundleID: String) -> URL? {
        let subpath: String?
        switch bundleID {
        case "com.google.Chrome":               subpath = "Google/Chrome"
        case "com.google.Chrome.beta":          subpath = "Google/Chrome Beta"
        case "com.google.Chrome.dev":           subpath = "Google/Chrome Dev"
        case "com.google.Chrome.canary":        subpath = "Google/Chrome Canary"
        case "com.brave.Browser":               subpath = "BraveSoftware/Brave-Browser"
        case "com.brave.Browser.beta":          subpath = "BraveSoftware/Brave-Browser-Beta"
        case "com.brave.Browser.dev":           subpath = "BraveSoftware/Brave-Browser-Dev"
        case "com.brave.Browser.nightly":       subpath = "BraveSoftware/Brave-Browser-Nightly"
        case "com.microsoft.edgemac":           subpath = "Microsoft Edge"
        case "com.microsoft.edgemac.Beta":      subpath = "Microsoft Edge Beta"
        case "com.microsoft.edgemac.Dev":       subpath = "Microsoft Edge Dev"
        case "com.microsoft.edgemac.Canary":    subpath = "Microsoft Edge Canary"
        case "com.vivaldi.Vivaldi":             subpath = "Vivaldi"
        case "com.operasoftware.Opera":         subpath = "com.operasoftware.Opera"
        default:                                subpath = nil
        }
        guard let subpath else { return nil }
        return appSupport().appendingPathComponent(subpath, isDirectory: true)
    }

    private static func readChromiumLocalState(in folder: URL) -> [ProfileInfo] {
        let localStateURL = folder.appendingPathComponent("Local State")
        guard
            let data = try? Data(contentsOf: localStateURL),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profile = json["profile"] as? [String: Any],
            let info = profile["info_cache"] as? [String: [String: Any]]
        else { return [] }

        return info
            .map { (dirName, attrs) -> ProfileInfo in
                let display = (attrs["name"] as? String)
                    ?? (attrs["user_name"] as? String)
                    ?? dirName
                return ProfileInfo(id: dirName, displayName: display)
            }
            .sorted { a, b in
                // "Default" is the most-likely choice; sort it first, then alpha.
                if a.id == "Default" { return true }
                if b.id == "Default" { return false }
                return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
            }
    }

    // MARK: - Firefox

    private static func readFirefoxProfilesIni() -> [ProfileInfo] {
        let iniURL = appSupport()
            .appendingPathComponent("Firefox", isDirectory: true)
            .appendingPathComponent("profiles.ini")
        guard let text = try? String(contentsOf: iniURL, encoding: .utf8) else { return [] }

        // INI format: section headers in [Brackets], key=value lines.
        // Profile sections look like [Profile0], [Profile1], etc.
        // Other sections ([General], [Install*]) we ignore.
        var profiles: [(name: String, isDefault: Bool)] = []
        var currentName: String?
        var currentDefault: Bool = false
        var inProfileSection = false

        func flush() {
            if inProfileSection, let n = currentName {
                profiles.append((name: n, isDefault: currentDefault))
            }
            currentName = nil
            currentDefault = false
            inProfileSection = false
        }

        for line in text.split(whereSeparator: { $0.isNewline }) {
            let raw = line.trimmingCharacters(in: .whitespaces)
            if raw.isEmpty || raw.hasPrefix(";") || raw.hasPrefix("#") { continue }
            if raw.hasPrefix("[") && raw.hasSuffix("]") {
                flush()
                let header = raw.dropFirst().dropLast()
                inProfileSection = header.lowercased().hasPrefix("profile")
                continue
            }
            guard inProfileSection else { continue }
            let parts = raw.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            switch key {
            case "Name":    currentName = value
            case "Default": currentDefault = (value == "1")
            default: break
            }
        }
        flush()

        return profiles
            .map { ProfileInfo(id: $0.name, displayName: $0.name) }
            .sorted { a, b in
                // Default profile first.
                if a.id == "default" { return true }
                if b.id == "default" { return false }
                return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
            }
    }

    // MARK: - Helpers

    private static func appSupport() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
}
