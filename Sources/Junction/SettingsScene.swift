import SwiftUI

/// The macOS Settings window (⌘,) — the single home for all of Junction's
/// UI now that it's a menu-bar-only app. The Activity tab replaces the
/// old standalone "Junction — Debug Log" window.
struct SettingsScene: View {

    enum Tab: Hashable {
        case rules
        case browsers
        case handoff
        case advanced
        case activity
    }

    @State private var selectedTab: Tab = .rules

    var body: some View {
        TabView(selection: $selectedTab) {
            RulesSettingsView()
                .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }
                .tag(Tab.rules)

            BrowsersSettingsView()
                .tabItem { Label("Browsers", systemImage: "app.badge") }
                .tag(Tab.browsers)

            HandoffSettingsView()
                .tabItem { Label("Handoff", systemImage: "arrow.up.right.square") }
                .tag(Tab.handoff)

            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
                .tag(Tab.advanced)

            DebugLogView()
                .tabItem { Label("Activity", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.activity)
        }
        .frame(minWidth: 720, idealWidth: 760, minHeight: 480, idealHeight: 540)
    }
}

#Preview { SettingsScene() }
