import AppKit
import Foundation

/// Decides where to send each received URL.
///
/// Flow at M4:
/// 1. Reject non-http(s) schemes early.
/// 2. Try the rule engine. If a rule matches, open silently in the rule's target.
/// 3. No match → show the picker. User's choice is treated as a one-shot rule.
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

        // 1. Rule match → silent route.
        if let rule = RuleEvaluator.evaluate(url, against: RuleStore.shared.rules) {
            open(
                url: url,
                target: rule.target,
                reason: .rule(name: rule.name),
                entryID: entryID
            )
            return
        }

        // 2. No match → picker.
        PickerController.shared.present(url: url) { [weak self] outcome in
            Task { @MainActor in
                switch outcome {
                case .picked(let browser):
                    let target = Target(browserBundleID: browser.bundleID)
                    self?.open(
                        url: url,
                        target: target,
                        reason: .picker,
                        entryID: entryID
                    )
                case .pickedAlways(let browser):
                    // Create a rule for this domain so the picker doesn't
                    // appear next time, then open the URL via that rule.
                    let target = Target(browserBundleID: browser.bundleID)
                    if let rule = self?.makeAlwaysRule(for: url, target: target) {
                        RuleStore.shared.add(rule)
                        self?.open(
                            url: url,
                            target: target,
                            reason: .rule(name: rule.name),
                            entryID: entryID
                        )
                    } else {
                        // URL has no host — fall back to a one-shot route.
                        self?.open(
                            url: url,
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
    /// selection for Chromium-based browsers. Firefox / Arc profiles work
    /// differently and land at M6.
    private func launchArguments(for target: Target) -> [String] {
        var args = target.extraArgs
        if let profile = target.profile,
           !profile.isEmpty,
           isChromiumBased(target.browserBundleID) {
            args.append("--profile-directory=\(profile)")
        }
        return args
    }

    private func isChromiumBased(_ bundleID: String) -> Bool {
        // The set of Chromium-family browsers that accept --profile-directory.
        // Keep in sync with BrowserDetector's known-IDs.
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
            // Arc (company.thebrowser.Browser) uses "Spaces", not profile directories.
            // Excluded intentionally — M6 will add proper Arc-style support.
        ]
        return chromium.contains(bundleID)
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
