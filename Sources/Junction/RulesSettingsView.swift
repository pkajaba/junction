import SwiftUI
import AppKit

/// Settings → Rules tab. Phase C redesign: replaces the flat list + modal
/// editor with a two-pane split view (sidebar with grouped rules, inline
/// editor on the right).
struct RulesSettingsView: View {

    @ObservedObject private var store = RuleStore.shared

    /// The id of the currently-edited rule. `nil` shows an empty-state
    /// "select a rule" message in the right pane.
    @State private var selection: UUID?

    /// User-typed search filter. Empty = show all rules.
    @State private var search: String = ""

    /// Lock the sidebar visible. Without this, NavigationSplitView shows a
    /// sidebar-toggle button in the top-left toolbar — and inside the
    /// macOS Settings scene's TabView, clicking that button bubbles up
    /// to the tab bar and shifts to the next tab. Pinning the column
    /// visibility removes the toggle and the bug with it.
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                // Belt-and-braces on the column width: the SwiftUI
                // `navigationSplitViewColumnWidth` modifier alone isn't
                // enforced when the Settings tab is hosted inside a manual
                // `NSWindow` (rather than SwiftUI's `Settings { ... }`
                // scene). A direct `.frame(minWidth:)` on the sidebar's
                // VStack guarantees the column never collapses below
                // something legible, regardless of split-view styling.
                .frame(minWidth: 280, idealWidth: 320)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 460)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            detailPane
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: store.rules.map(\.id)) { _, newIDs in
            // If our selection was deleted out from under us (external
            // edit to rules.json), pick a sensible fallback so the right
            // pane never sticks to a stale id.
            if let sel = selection, !newIDs.contains(sel) {
                selection = newIDs.first
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if groups.isEmpty {
                        sidebarEmpty
                    } else {
                        ForEach(groups) { group in
                            RuleGroupSection(
                                group: group,
                                selection: $selection
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            Divider()
            sidebarToolbar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        // Settings' TabView toolbar floats above content by default, so
        // without an explicit inset our "Rules" title renders behind the
        // tab buttons. Match the inset Apple uses in its own panes.
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Rules")
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
            }
            Text(subtitleText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Filter all rules", text: $search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var subtitleText: String {
        let total = store.rules.count
        let unit = total == 1 ? "rule" : "rules"
        if search.isEmpty {
            return "\(total) \(unit) · grouped by destination"
        }
        let shown = groups.reduce(0) { $0 + $1.rules.count }
        return "Showing \(shown) of \(total) \(unit)"
    }

    private var sidebarEmpty: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(search.isEmpty ? "No rules yet" : "No rules match")
                .font(.system(size: 13, weight: .semibold))
            if search.isEmpty {
                Button {
                    addRule()
                } label: {
                    Label("Add rule", systemImage: "plus")
                }
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var sidebarToolbar: some View {
        HStack(spacing: 4) {
            Button {
                addRule()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Add rule")

            Button {
                if let id = selection { store.delete(id: id); selection = nil }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .disabled(selection == nil)
            .help("Delete selected rule")

            Spacer()

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([RuleStore.storeURL])
            } label: {
                Label("rules.json", systemImage: "doc.text")
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailPane: some View {
        if let selectedRule = store.rules.first(where: { $0.id == selection }) {
            // Bind through the store: every mutation in the editor
            // immediately persists, FileWatcher loop suppression in
            // RuleStore keeps it from cascading.
            RuleEditorView(
                rule: Binding(
                    get: { selectedRule },
                    set: { store.update($0) }
                )
            )
        } else {
            detailEmpty
        }
    }

    private var detailEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Select a rule")
                .font(.title3.weight(.semibold))
            Text("Or use **+** to add a new one.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Grouping logic

    /// Rules grouped by target browser, filtered by search.
    private var groups: [RuleGroup] {
        let filtered = filteredRules
        let buckets = Dictionary(grouping: filtered, by: \.target.browserBundleID)

        return buckets
            .map { bundleID, rules in
                RuleGroup(
                    bundleID: bundleID,
                    displayName: browserDisplayName(bundleID),
                    rules: rules
                )
            }
            .sorted { a, b in
                a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
            }
    }

    private var filteredRules: [Rule] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return store.rules }
        return store.rules.filter { rule in
            // Search the things the user can see on a rule row:
            // - the rule's own name
            // - the matcher's host/regex/contains string
            // - the target browser by **display** name (so "google chrome"
            //   works, not just "chrome" via the bundle ID) and bundle ID
            // - source app display names + bundle IDs (so a "slack" search
            //   surfaces "from Slack" rules)
            let browserName = browserDisplayName(rule.target.browserBundleID).lowercased()
            let sourceNames = rule.sourceApps
                .map { SourceAppList.displayName(for: $0).lowercased() }
            let sourceIDs = rule.sourceApps.map { $0.lowercased() }
            return rule.name.lowercased().contains(q)
                || matcherSummary(rule.match).lowercased().contains(q)
                || rule.target.browserBundleID.lowercased().contains(q)
                || browserName.contains(q)
                || sourceNames.contains(where: { $0.contains(q) })
                || sourceIDs.contains(where: { $0.contains(q) })
        }
    }

    private func browserDisplayName(_ bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default
                .displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }

    private func matcherSummary(_ matcher: Matcher) -> String {
        switch matcher {
        case .host(let v):        return v
        case .hostRegex(let v):   return v
        case .urlContains(let v): return v
        case .any:                return "any URL"
        }
    }

    // MARK: - Actions

    private func addRule() {
        // Generate a sensible starter target: prefer the most-used
        // existing target so a new rule plays nicely with the user's
        // setup. Falls back to Safari.
        let defaultBundle = mostUsedTargetBundleID() ?? "com.apple.Safari"
        let new = Rule(
            name: "New rule",
            match: .host(""),
            target: Target(browserBundleID: defaultBundle)
        )
        store.add(new)
        selection = new.id
    }

    private func mostUsedTargetBundleID() -> String? {
        Dictionary(grouping: store.rules, by: \.target.browserBundleID)
            .max(by: { $0.value.count < $1.value.count })?.key
    }
}

// MARK: - Group model

struct RuleGroup: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let rules: [Rule]
    var id: String { bundleID }
}

// MARK: - Group section view

private struct RuleGroupSection: View {
    let group: RuleGroup
    @Binding var selection: UUID?

    @State private var expanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                        .foregroundStyle(.secondary)
                    BrowserIcon(bundleID: group.bundleID, size: 14)
                    Text(group.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                    Spacer()
                    Text("\(group.rules.count)")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(group.rules) { rule in
                    RuleRow(rule: rule, isSelected: rule.id == selection) {
                        selection = rule.id
                    }
                }
            }
        }
    }
}

// MARK: - Rule row

private struct RuleRow: View {
    let rule: Rule
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(rule.enabled ? Color.green : Color.secondary)
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.name)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .lineLimit(1)
                    Text(matcherSummary)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(isSelected
                                         ? Color.white.opacity(0.7)
                                         : Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                if let profile = rule.target.profile, !profile.isEmpty {
                    ProfileChip(name: profile, isSelected: isSelected)
                }
            }
            .padding(.leading, 22)
            .padding(.trailing, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .opacity(rule.enabled ? 1.0 : 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private var matcherSummary: String {
        let urlPart: String
        switch rule.match {
        case .host(let v):        urlPart = v.isEmpty ? "—" : v
        case .hostRegex(let v):   urlPart = v
        case .urlContains(let v): urlPart = "contains: \(v)"
        case .any:                urlPart = "any URL"
        }
        if !rule.sourceApps.isEmpty {
            let names = rule.sourceApps.map(SourceAppList.displayName(for:))
            return "\(urlPart)  ·  from \(ListFormatter.localizedString(byJoining: names))"
        }
        return urlPart
    }
}

private struct ProfileChip: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.18) : Color.primary.opacity(0.08))
            )
    }
}

// MARK: - Browser icon helper

/// Wrapper that loads an `NSImage` from a bundle ID at any size. Falls
/// back to a generic SF Symbol if the app can't be located.
struct BrowserIcon: View {
    let bundleID: String
    let size: CGFloat

    var body: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(.tertiary)
        }
    }
}
