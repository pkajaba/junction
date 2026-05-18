import SwiftUI

/// The macOS Settings window (⌘,), housing the Rules and Browsers tabs.
struct SettingsScene: View {

    enum Tab: Hashable {
        case rules
        case browsers
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
        }
        .frame(minWidth: 720, idealWidth: 760, minHeight: 480, idealHeight: 540)
    }
}

#Preview { SettingsScene() }
