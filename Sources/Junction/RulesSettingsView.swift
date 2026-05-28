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

    /// Cross-tab coordinator — observed so a queued "create rule from
    /// Activity" selection gets picked up here.
    @ObservedObject private var coordinator = SettingsCoordinator.shared

    /// Persists across Settings re-opens, per the Round 2 ② handoff spec.
    /// Defaults to `.destination` for new installs (matches old behavior).
    @AppStorage("JunctionRulesGrouping") private var groupingRaw: String = RulesGrouping.destination.rawValue

    private var grouping: RulesGrouping {
        RulesGrouping(rawValue: groupingRaw) ?? .destination
    }

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
        // "Create rule from Activity" switches to this tab and queues a
        // rule id; select it. Check on appear (the tab may have just
        // been switched to, so onChange won't fire for the pre-set
        // value) and on change (already on this tab).
        .onAppear(perform: consumePendingSelection)
        .onChange(of: coordinator.pendingRuleSelection) { _, _ in
            consumePendingSelection()
        }
    }

    private func consumePendingSelection() {
        guard let id = coordinator.pendingRuleSelection else { return }
        selection = id
        coordinator.pendingRuleSelection = nil
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
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row: "Rules" on the left, +/− cluster on the right.
            // Moving the add button into the header makes it a primary
            // action — discoverable at first glance — instead of buried
            // in a bottom toolbar.
            HStack(alignment: .center, spacing: 6) {
                Text("Rules")
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
                SidebarMinusButton(
                    isEnabled: selection != nil,
                    action: deleteSelected
                )
                SidebarPlusButton(action: addRule)
            }
            // Meta row: count + grouping pill. The pill opens a menu of
            // grouping options (Destination / Source app / Match type /
            // Nothing). Search active → text changes to "Showing N of M".
            HStack(spacing: 4) {
                Text(metaCountText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if search.isEmpty {
                    Text(" · grouped by")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    groupingPill
                }
            }
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

    /// The "[destination ▾]" pill. Tapping opens a menu of the four
    /// grouping options; the current selection has a leading checkmark.
    private var groupingPill: some View {
        Menu {
            ForEach(RulesGrouping.allCases, id: \.self) { option in
                Button {
                    groupingRaw = option.rawValue
                } label: {
                    if option == grouping {
                        Label(option.menuTitle, systemImage: "checkmark")
                    } else {
                        Text(option.menuTitle)
                    }
                    Text(option.menuSubtitle)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(grouping.pillLabel)
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var metaCountText: String {
        let total = store.rules.count
        let unit = total == 1 ? "rule" : "rules"
        if search.isEmpty {
            return "\(total) \(unit)"
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
            Spacer()
            // The +/− cluster moved to the header in the Round 2 ②
            // redesign, so this bottom strip is just a deep-link to
            // rules.json for power users.
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

    private func deleteSelected() {
        guard let id = selection else { return }
        store.delete(id: id)
        selection = nil
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

    /// Rules bucketed according to the user's chosen grouping, filtered
    /// by the search field. Bucketing lives on `RulesGrouping` so this
    /// view stays focused on rendering.
    private var groups: [RuleGroup] {
        grouping.buckets(of: filteredRules)
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
        case .urlPrefix(let v):   return v
        case .any:                return "any URL"
        }
    }

    // MARK: - Actions

    private func addRule() {
        // Generate a sensible starter target: prefer the most-used
        // existing target so a new rule plays nicely with the user's
        // setup. Falls back to Safari.
        let defaultBundle = mostUsedTargetBundleID() ?? "com.apple.Safari"
        // Start with a target-aware placeholder ("Untitled → Safari") so
        // the rule reads as something instead of "New rule" in the
        // sidebar. The editor will keep refining the name as the user
        // adds host chips — see RuleEditorView's auto-name behavior.
        let new = Rule(
            name: Rule.placeholderName(forTarget: defaultBundle),
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
