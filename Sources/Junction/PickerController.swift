import AppKit
import SwiftUI

/// Manages the picker window's lifecycle and serializes overlapping picker
/// requests.
///
/// Junction shows one picker at a time. If a URL arrives while a picker is
/// already on screen, it goes on a queue and the picker pops up for it once
/// the current request resolves. This keeps the UX predictable even under
/// rapid link-clicks.
@MainActor
final class PickerController: NSObject {

    static let shared = PickerController()

    /// Outcome of a single picker session.
    enum Outcome: Equatable {
        /// User picked a browser for this URL only.
        case picked(DetectedBrowser)
        /// User picked a browser AND held Option — Router will save a rule
        /// so this domain skips the picker next time.
        case pickedAlways(DetectedBrowser)
        case cancelled
    }

    // MARK: - State

    private var window: NSWindow?
    private var hostingController: NSHostingController<PickerView>?
    private var resignKeyObserver: Any?

    private struct PendingRequest {
        let url: URL
        let completion: (Outcome) -> Void
    }
    private var queue: [PendingRequest] = []
    private var isPresenting = false

    private override init() {
        super.init()
    }

    // MARK: - Public

    /// Present the picker for `url`. Calls `completion` on the main actor
    /// when the user picks a browser or cancels.
    func present(url: URL, completion: @escaping (Outcome) -> Void) {
        queue.append(PendingRequest(url: url, completion: completion))
        presentNextIfNeeded()
    }

    // MARK: - Queue plumbing

    private func presentNextIfNeeded() {
        guard !isPresenting, !queue.isEmpty else { return }
        let request = queue.removeFirst()
        isPresenting = true
        show(url: request.url) { [weak self] outcome in
            request.completion(outcome)
            self?.isPresenting = false
            self?.presentNextIfNeeded()
        }
    }

    // MARK: - Window lifecycle

    private func show(url: URL, onResolve: @escaping (Outcome) -> Void) {
        let browsers = BrowserDetector.shared.detect()

        // Resolve once, exactly once — protect against the user clicking AND
        // pressing Enter, or the window closing for any other reason.
        var hasResolved = false
        let resolveOnce: (Outcome) -> Void = { [weak self] outcome in
            guard !hasResolved else { return }
            hasResolved = true
            self?.dismiss()
            onResolve(outcome)
        }

        let view = PickerView(
            url: url,
            browsers: browsers,
            onResolve: resolveOnce
        )

        let hosting = NSHostingController(rootView: view)
        let window = makeWindow(content: hosting)

        self.window = window
        self.hostingController = hosting

        // Click-outside dismisses. We used to install a global mouse-down
        // monitor (`NSEvent.addGlobalMonitorForEvents`) but those don't
        // reliably fire for `LSUIElement` apps on macOS 14+ unless the
        // user has granted accessibility permission — which isn't a
        // reasonable ask for an app launcher.
        //
        // `windowDidResignKey` is the dependable signal: any click that
        // hands focus to another window (ours or someone else's) takes
        // key status away from the picker, and that's exactly the
        // "dismiss me" moment. Activating the app + ordering the window
        // front first ensures the window IS key before we start
        // observing — otherwise we'd see a spurious resign on activation.
        centerOnActiveDisplay(window: window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { _ in
            resolveOnce(.cancelled)
        }
    }

    private func dismiss() {
        if let observer = resignKeyObserver {
            NotificationCenter.default.removeObserver(observer)
            resignKeyObserver = nil
        }
        window?.orderOut(nil)
        window = nil
        hostingController = nil
    }

    private func makeWindow(content: NSViewController) -> NSWindow {
        let window = PickerNSWindow(contentViewController: content)
        window.styleMask = [.borderless]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovable = false
        window.isReleasedWhenClosed = false
        return window
    }

    private func centerOnActiveDisplay(window: NSWindow) {
        guard let screen = activeScreen() else { return }
        // Force layout so frame.size is real before we position.
        window.layoutIfNeeded()
        let visible = screen.visibleFrame
        let size = window.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.05  // a hair above center reads better
        )
        window.setFrameOrigin(origin)
    }

    /// The screen the user is currently looking at — best-effort via cursor
    /// position. Falls back to the main screen if nothing matches.
    private func activeScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        for screen in NSScreen.screens where NSMouseInRect(mouse, screen.frame, false) {
            return screen
        }
        return NSScreen.main
    }
}

/// Borderless `NSWindow` that can receive keyboard focus.
/// By default, borderless windows return `false` for `canBecomeKey`, which
/// would block all keyboard events — including `.onKeyPress` in our SwiftUI
/// content.
private final class PickerNSWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
