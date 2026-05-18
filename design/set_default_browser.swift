// set_default_browser.swift
//
// Sets a given app as the macOS default handler for http:// and https://
// URLs. Uses NSWorkspace.setDefaultApplication (macOS 12+), which calls
// the same Launch Services API the System Settings UI uses internally.
//
// We use this because Tahoe's default-browser DROPDOWN filters to apps
// with proper Developer-ID signing — ad-hoc signed apps (like a local
// Junction build) won't appear in the UI. The underlying API has no
// such filter; you can still set any registered app as default.
//
// Usage:
//   swift set_default_browser.swift /Applications/Junction.app
//   swift set_default_browser.swift com.apple.Safari
//   swift set_default_browser.swift se.johnste.finicky     # revert to Finicky
//
// What it actually does: nothing more than calling the same API the
// "Default web browser" dropdown calls when you pick something there.

import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: \(args[0]) <app-path-or-bundle-id>")
    print("Examples:")
    print("  \(args[0]) /Applications/Junction.app")
    print("  \(args[0]) com.apple.Safari")
    print("  \(args[0]) se.johnste.finicky")
    exit(1)
}

let target = args[1]

// Resolve target to a file URL — accept either a path or a bundle id.
let appURL: URL
if target.hasPrefix("/") || target.hasPrefix("~") {
    appURL = URL(fileURLWithPath: NSString(string: target).expandingTildeInPath)
    guard FileManager.default.fileExists(atPath: appURL.path) else {
        print("error: no app at \(appURL.path)")
        exit(1)
    }
} else if let resolved = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target) {
    appURL = resolved
} else {
    print("error: could not resolve '\(target)' to an app (try the full path?)")
    exit(1)
}

print("Setting default for http/https → \(appURL.lastPathComponent)")
print("                                  (\(appURL.path))")
print()

let group = DispatchGroup()
var failures: [(scheme: String, error: Error)] = []

for scheme in ["http", "https"] {
    group.enter()
    NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme) { error in
        if let error {
            failures.append((scheme, error))
            print("  ✗ \(scheme): \(error.localizedDescription)")
        } else {
            print("  ✓ \(scheme)")
        }
        group.leave()
    }
}

// Wait for both callbacks (or time out after 5s).
_ = group.wait(timeout: .now() + 5)

if failures.isEmpty {
    print()
    print("Done. macOS may prompt you to confirm.")
} else {
    exit(1)
}
