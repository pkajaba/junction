import AppKit
import Foundation

/// Decides where to send each received URL.
///
/// Flow at M6:
/// 1. Reject non-http(s) schemes early.
/// 2. Apply `URLRewriter` (e.g. strip tracking params).
/// 3. Try the rule engine against the rewritten URL.
/// 4. If a rule matches, open silently in the rule's target.
/// 5. No match → show the picker. User's choice is treated as a one-shot route,
///    unless ⌥ is held in which case Junction creates a rule for the host.
@MainActor
final class Router {

    static let shared = Router()
    private init() {}

    /// Entry point for every received URL.
    func route(_ url: URL, entryID: UUID) {
        guard isRoutableScheme(url) else {
            URLLog.shared.updateRouting(for: entryID, to: .unsupported)
            return
        }

        // Rewrite (currently: strip tracking params) before matching/opening.
        let cleaned = URLRewriter.rewrite(url, settings: RewriterSettings.shared)
        if cleaned != url {
            URLLog.shared.updateRewritten(for: entryID, to: cleaned)
        }
        let target_url = cleaned

        // 1. Rule match → silent route.
        if let rule = RuleEvaluator.evaluate(target_url, against: RuleStore.shared.rules) {
            open(
                url: target_url,
                target: rule.target,
                reason: .rule(name: rule.name),
                entryID: entryID
            )
            return
        }

        // 2. No match → picker.
        PickerController.shared.present(url: target_url) { [weak self] outcome in
            Task { @MainActor in
                switch outcome {
                case .picked(let browser):
                    let target = Target(browserBundleID: browser.bundleID)
                    self?.open(
                        url: target_url,
                        target: target,
                        reason: .picker,
                        entryID: entryID
                    )
                case .pickedAlways(let browser):
                    let target = Target(browserBundleID: browser.bundleID)
                    if let rule = self?.makeAlwaysRule(for: target_url, target: target) {
                        RuleStore.shared.add(rule)
                        self?.open(
                            url: target_url,
                            target: target,
                            reason: .rule(name: rule.name),
                            entryID: entryID
                        )
                    } else {
                        self?.open(
                            url: target_url,
                            target: target,
                            reason: .picker,
                            entryID: entryID
                        )
                    }
                case .cancelled:
                    URLLog.shared.updateRouting(for: entryID, to: .cancelled)
                }
            }
        }
    }

    // MARK: - Open with target

    private func open(
        url: URL,
        target: Target,
        reason: URLLog.RouteReason,
        entryID: UUID
    ) {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: target.browserBundleID
        ) else {
            URLLog.shared.updateRouting(
                for: entryID,
                to: .failed(reason: "Browser \(target.browserBundleID) not installed")
            )
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.arguments = launchArguments(for: target)
        config.createsNewApplicationInstance = target.openInNewWindow

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: config
        ) { _, error in
            Task { @MainActor in
                if let error {
                    URLLog.shared.updateRouting(
                        for: entryID,
                        to: .failed(reason: error.localizedDescription)
                    )
                } else {
                    let name = FileManager.default
                        .displayName(atPath: appURL.path)
                        .replacingOccurrences(of: ".app", with: "")
                    URLLog.shared.updateRouting(
                        for: entryID,
                        to: .routed(to: name, via: reason)
                    )
                }
            }
        }
    }

    // MARK: - Per-browser launch arg quirks

    /// Build CLI arguments for the launched browser, handling profile
    /// selection per browser family.
    ///
    /// - **Chromium** (Chrome, Brave, Edge, Vivaldi, Opera): `--profile-directory=<dir>`
    /// - **Firefox**: `-P <name>` (only effective on cold launch — if Firefox
    ///   is already running with a different profile, the flag is mostly
    ///   ignored. Power users should pair Firefox profiles with the rule's
    ///   "Open in new window" toggle.)
    /// - **Safari / Arc**: profile field ignored (profile model differs;
    ///   future work).
    private func launchArguments(for target: Target) -> [String] {
        var args = target.extraArgs
        guard let profile = target.profile, !profile.isEmpty else { return args }

        if isChromiumBased(target.browserBundleID) {
            args.append("--profile-directory=\(profile)")
        } else if isFirefoxFamily(target.browserBundleID) {
            args.append(contentsOf: ["-P", profile])
        }
        return args
    }

    private func isChromiumBased(_ bundleID: String) -> Bool {
        let chromium: Set<String> = [
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "com.google.Chrome.beta",
            "com.google.Chrome.dev",
            "com.brave.Browser",
            "com.brave.Browser.dev",
            "com.brave.Browser.beta",
            "com.brave.Browser.nightly",
            "com.microsoft.edgemac",
            "com.microsoft.edgemac.Beta",
            "com.microsoft.edgemac.Dev",
            "com.microsoft.edgemac.Canary",
            "com.vivaldi.Vivaldi",
            "com.operasoftware.Opera",
        ]
        return chromium.contains(bundleID)
    }

    private func isFirefoxFamily(_ bundleID: String) -> Bool {
        let firefox: Set<String> = [
            "org.mozilla.firefox",
            "org.mozilla.firefoxdeveloperedition",
            "org.mozilla.nightly",
        ]
        return firefox.contains(bundleID)
    }

    // MARK: - "Always" rule construction

    /// Build a Rule that captures "always send this URL's domain here".
    /// Returns nil for URLs that have no host (which the scheme guard
    /// should already reject, but defensive).
    private func makeAlwaysRule(for url: URL, target: Target) -> Rule? {
        guard let host = url.host, !host.isEmpty else { return nil }
        let browserName = NSWorkspace.shared
            .urlForApplication(withBundleIdentifier: target.browserBundleID)
            .map { FileManager.default.displayName(atPath: $0.path)
                .replacingOccurrences(of: ".app", with: "") }
            ?? target.browserBundleID
        return Rule(
            name: "Always \(host) → \(browserName)",
            match: .host(host),
            target: target
        )
    }

    // MARK: - Scheme guard

    private func isRoutableScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}
