import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so Junction can launch itself at login.
///
/// For a menu-bar router this matters: if Junction isn't running, links
/// don't route — they fall back to the OS default. Registering as a
/// login item means it's up the moment you log in.
///
/// `SMAppService` (macOS 13+) is the modern path — no helper bundle, no
/// deprecated `LSSharedFileList`. The toggle reads the *live* status, so
/// it stays correct even if the user flips the switch in System
/// Settings → General → Login Items instead of here.
@MainActor
final class LoginItemSettings: ObservableObject {

    static let shared = LoginItemSettings()

    /// Mirrors `SMAppService.mainApp.status == .enabled`. Published so the
    /// Settings toggle reflects external changes after a `refresh()`.
    @Published private(set) var isEnabled: Bool

    /// Set when a register/unregister throws, so the UI can explain why
    /// the toggle didn't take.
    @Published private(set) var lastError: String?

    private init() {
        isEnabled = Self.service.status == .enabled
    }

    private static var service: SMAppService { .mainApp }

    /// Register or unregister Junction as a login item. Re-reads the live
    /// status afterward so `isEnabled` reflects what actually happened
    /// (e.g. macOS may park the request in "requires approval").
    func setEnabled(_ enabled: Bool) {
        lastError = nil
        do {
            if enabled {
                try Self.service.register()
            } else {
                try Self.service.unregister()
            }
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    /// Re-read the live status from the system. Call on Settings appear
    /// so a change made in System Settings is reflected.
    func refresh() {
        isEnabled = Self.service.status == .enabled
    }

    /// True when macOS has deferred the login item to user approval in
    /// System Settings → General → Login Items. The toggle reads as off
    /// in that state; the hint nudges the user to approve.
    var requiresApproval: Bool {
        Self.service.status == .requiresApproval
    }
}
