import AppKit

/// Owns Junction's status-bar item — the persistent menu-bar affordance
/// that replaces the Dock icon now that the app is `LSUIElement`-true.
///
/// The menu is small on purpose: a router shouldn't accumulate UI for the
/// sake of it. Settings is where everything configurable lives; this menu
/// exists so the user can *reach* Settings, peek at recent routing, and
/// quit. Nothing more.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {

    static let shared = MenuBarController()

    private var statusItem: NSStatusItem!
    private let recentURLsSubmenu = NSMenu(title: "Recent URLs")
    private let maxRecentURLs = 5

    private override init() {
        super.init()
        configure()
    }

    // MARK: - Setup

    private func configure() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.behavior = []  // keep the icon visible across logins/displays

        if let button = statusItem.button {
            // SF Symbols render at their natural size by default — visibly
            // larger than neighboring menu-bar glyphs. 15 pt regular matches
            // the weight Apple uses for Wi-Fi, battery, etc.
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            let icon = NSImage(
                systemSymbolName: "arrow.triangle.branch",
                accessibilityDescription: "Junction"
            )?
            .withSymbolConfiguration(config)
            icon?.isTemplate = true   // adapts to menu-bar light/dark + tinted modes
            button.image = icon
            button.toolTip = "Junction — link router"
        }

        statusItem.menu = buildMenu()
    }

    // MARK: - Menu construction

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        menu.addItem(makeItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(.separator())

        // Recent URLs submenu — populated lazily via NSMenuDelegate so it
        // always reflects the latest URLLog without a Combine subscription.
        let recentItem = NSMenuItem(title: "Recent URLs", action: nil, keyEquivalent: "")
        recentItem.submenu = recentURLsSubmenu
        recentURLsSubmenu.delegate = self
        menu.addItem(recentItem)

        let reloadItem = makeItem(
            title: "Reload Rules",
            action: #selector(reloadRules),
            keyEquivalent: "r"
        )
        reloadItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(reloadItem)

        menu.addItem(makeItem(
            title: "Reveal rules.json in Finder",
            action: #selector(revealRules),
            keyEquivalent: ""
        ))

        menu.addItem(.separator())

        menu.addItem(makeItem(
            title: "Quit Junction",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        return menu
    }

    private func makeItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === recentURLsSubmenu else { return }

        recentURLsSubmenu.removeAllItems()
        let recent = URLLog.shared.entries.suffix(maxRecentURLs).reversed()

        guard !recent.isEmpty else {
            let placeholder = NSMenuItem(title: "No recent URLs", action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            recentURLsSubmenu.addItem(placeholder)
            return
        }

        for entry in recent {
            let item = NSMenuItem(
                title: truncated(entry.url.absoluteString),
                action: #selector(reopenRecent(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = entry.url
            item.toolTip = entry.url.absoluteString
            recentURLsSubmenu.addItem(item)
        }
    }

    private func truncated(_ urlString: String, limit: Int = 70) -> String {
        guard urlString.count > limit else { return urlString }
        return String(urlString.prefix(limit - 1)) + "…"
    }

    // MARK: - Actions

    @objc private func openSettings() {
        // Present the window directly rather than going through the
        // `showSettingsWindow:` responder action. The action dispatch is
        // unreliable for `LSUIElement` apps — see SettingsWindowController.
        SettingsWindowController.shared.show()
    }

    @objc private func reloadRules() {
        RuleStore.shared.load()
    }

    @objc private func revealRules() {
        NSWorkspace.shared.activateFileViewerSelecting([RuleStore.storeURL])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func reopenRecent(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        let id = URLLog.shared.append(url, source: .openURLs)
        Router.shared.route(url, entryID: id)
    }
}
