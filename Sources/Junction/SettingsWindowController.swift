import AppKit
import SwiftUI
import Combine

/// Cross-tab coordinator for the Settings window. Shared singleton so any
/// tab (and the AppKit toolbar) can read/write the current tab and hand
/// off a "go here next" action — e.g. the Activity tab building a rule
/// and revealing it in the Rules tab.
@MainActor
final class SettingsCoordinator: ObservableObject {
    static let shared = SettingsCoordinator()

    /// Which Settings pane is visible. Written by the toolbar's
    /// segmented control and by cross-tab actions.
    @Published var tab: SettingsWindowController.Tab = .rules

    /// When set, the Rules tab selects this rule on next render and
    /// clears the value. Used by "Create rule from Activity".
    @Published var pendingRuleSelection: UUID?

    private init() {}

    /// Add a rule, switch to the Rules tab, and queue it for selection —
    /// the one-click "turn this link into a rule" path from Activity.
    func createRuleAndReveal(_ rule: Rule) {
        RuleStore.shared.add(rule)
        pendingRuleSelection = rule.id
        tab = .rules
    }
}

/// Owns the Settings window for Junction's menu-bar (`LSUIElement`) life.
///
/// We don't use SwiftUI's `Settings { … }` scene: `showSettingsWindow:`
/// silently no-ops for an accessory app even after promoting to
/// `.regular` activation (a long-standing macOS limitation). Instead we
/// build the window ourselves with a real `NSToolbar` carrying a
/// centered segmented tab control — the same chrome the native Settings
/// scene renders (tabs in the toolbar, panes filling edge-to-edge),
/// just under our control so it opens reliably.
@MainActor
final class SettingsWindowController: NSObject, NSToolbarDelegate {

    static let shared = SettingsWindowController()

    /// The Settings tabs, in display order.
    enum Tab: String, CaseIterable {
        case rules = "Rules"
        case browsers = "Browsers"
        case handoff = "Handoff"
        case advanced = "Advanced"
        case activity = "Activity"

        var title: String { rawValue }
    }

    private let coordinator = SettingsCoordinator.shared
    private var window: NSWindow?
    private weak var segmented: NSSegmentedControl?
    private var closeObserver: Any?
    private var tabObserver: AnyCancellable?

    private static let toolbarID = NSToolbar.Identifier("JunctionSettingsToolbar")
    private static let tabsItemID = NSToolbarItem.Identifier("JunctionTabs")

    private override init() { super.init() }

    // MARK: - Show

    func show() {
        // Dock icon + activation while Settings is open; demote on close.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if window == nil {
            window = makeWindow()
        }
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    /// Open Settings already focused on a particular tab — used by
    /// cross-tab actions (e.g. "create rule from Activity").
    func show(tab: Tab) {
        coordinator.tab = tab
        show()
    }

    // MARK: - Window construction

    private func makeWindow() -> NSWindow {
        // Keep the toolbar's segmented control in sync when the tab is
        // changed programmatically (e.g. createRuleAndReveal switches to
        // Rules). User-driven changes go the other way via tabChanged.
        tabObserver = coordinator.$tab.sink { [weak self] tab in
            self?.segmented?.selectedSegment = Tab.allCases.firstIndex(of: tab) ?? 0
        }

        let root = SettingsRootView(coordinator: coordinator)
        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Junction Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 820, height: 560))
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("JunctionSettings")
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]

        let toolbar = NSToolbar(identifier: Self.toolbarID)
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifier = Self.tabsItemID
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Task { @MainActor in NSApp.setActivationPolicy(.accessory) }
        }

        return window
    }

    // MARK: - Toolbar delegate

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.tabsItemID]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.tabsItemID]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard itemIdentifier == Self.tabsItemID else { return nil }
        let item = NSToolbarItem(itemIdentifier: Self.tabsItemID)
        let control = NSSegmentedControl(
            labels: Tab.allCases.map(\.title),
            trackingMode: .selectOne,
            target: self,
            action: #selector(tabChanged(_:))
        )
        control.segmentStyle = .texturedRounded
        control.selectedSegment = Tab.allCases.firstIndex(of: coordinator.tab) ?? 0
        item.view = control
        segmented = control
        return item
    }

    @objc private func tabChanged(_ sender: NSSegmentedControl) {
        let idx = sender.selectedSegment
        guard Tab.allCases.indices.contains(idx) else { return }
        coordinator.tab = Tab.allCases[idx]
    }
}

// MARK: - Root content

/// Hosts whichever tab is selected. No `TabView` — the toolbar provides
/// the tab affordance, so this just switches on the shared coordinator.
struct SettingsRootView: View {
    @ObservedObject var coordinator: SettingsCoordinator

    var body: some View {
        Group {
            switch coordinator.tab {
            case .rules:    RulesSettingsView()
            case .browsers: BrowsersSettingsView()
            case .handoff:  HandoffSettingsView()
            case .advanced: AdvancedSettingsView()
            case .activity: DebugLogView()
            }
        }
        .frame(minWidth: 720, idealWidth: 820, minHeight: 480, idealHeight: 560)
    }
}
