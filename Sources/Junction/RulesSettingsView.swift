import SwiftUI

/// Settings → Rules tab.
///
/// Lists the user's rules with add/edit/delete and drag-to-reorder.
/// Tapping a row (or pressing Return) opens `RuleEditorView` as a sheet.
struct RulesSettingsView: View {

    @ObservedObject private var store = RuleStore.shared

    @State private var editing: EditingState?
    @State private var selection: UUID?

    /// What's currently open in the editor sheet, if anything.
    private enum EditingState: Identifiable {
        case adding
        case editing(Rule)

        var id: String {
            switch self {
            case .adding: return "new"
            case .editing(let rule): return rule.id.uuidString
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            list
            Divider()
            footer
        }
        .sheet(item: $editing) { state in
            sheet(for: state)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rules")
                .font(.title2.weight(.semibold))
            Text("URLs are matched against rules in order; the first enabled match wins. URLs that don't match any rule pop up the picker.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(20)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if store.rules.isEmpty {
            empty
        } else {
            List(selection: $selection) {
                ForEach(store.rules) { rule in
                    RuleRow(rule: rule)
                        .tag(rule.id)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            editing = .editing(rule)
                        }
                }
                .onMove { source, destination in
                    store.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { offsets in
                    for idx in offsets {
                        store.delete(id: store.rules[idx].id)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No rules yet")
                .font(.title3.weight(.semibold))
            Text("Add a rule to send specific URLs straight to a browser, skipping the picker.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                editing = .adding
            } label: {
                Label("Add rule", systemImage: "plus")
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Button(action: { editing = .adding }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Add rule")

            Button(action: deleteSelected) {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(selection == nil)
            .help("Delete selected rule")

            Button(action: editSelected) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .disabled(selection == nil)
            .help("Edit selected rule (or double-click row)")

            Spacer()

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([RuleStore.storeURL])
            } label: {
                Label("Reveal rules.json", systemImage: "doc.text.magnifyingglass")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func deleteSelected() {
        guard let id = selection else { return }
        store.delete(id: id)
        selection = nil
    }

    private func editSelected() {
        guard let id = selection, let rule = store.rules.first(where: { $0.id == id }) else { return }
        editing = .editing(rule)
    }

    // MARK: - Sheet

    @ViewBuilder
    private func sheet(for state: EditingState) -> some View {
        switch state {
        case .adding:
            RuleEditorView(
                initial: Self.blankRule(),
                isNew: true,
                onSave: { rule in
                    store.add(rule)
                    editing = nil
                },
                onCancel: { editing = nil }
            )
        case .editing(let rule):
            RuleEditorView(
                initial: rule,
                isNew: false,
                onSave: { updated in
                    store.update(updated)
                    editing = nil
                },
                onCancel: { editing = nil }
            )
        }
    }

    private static func blankRule() -> Rule {
        Rule(
            name: "New rule",
            match: .host(""),
            target: Target(browserBundleID: "com.apple.Safari")
        )
    }
}

// MARK: - Row

private struct RuleRow: View {
    let rule: Rule

    var body: some View {
        HStack(spacing: 12) {
            statusDot
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body.weight(.medium))
                    .strikethrough(!rule.enabled, color: .secondary)
                    .foregroundStyle(rule.enabled ? .primary : .secondary)
                HStack(spacing: 6) {
                    matcherSummary
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    targetSummary
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusDot: some View {
        Circle()
            .fill(rule.enabled ? Color.green : Color.gray.opacity(0.4))
            .frame(width: 8, height: 8)
    }

    @ViewBuilder
    private var matcherSummary: some View {
        switch rule.match {
        case .host(let v):
            Text("host: ").foregroundStyle(.tertiary)
            Text(v).font(.system(.caption, design: .monospaced))
        case .hostRegex(let v):
            Text("regex: ").foregroundStyle(.tertiary)
            Text(v).font(.system(.caption, design: .monospaced))
        case .urlContains(let v):
            Text("contains: ").foregroundStyle(.tertiary)
            Text(v).font(.system(.caption, design: .monospaced))
        }
    }

    private var targetSummary: some View {
        HStack(spacing: 4) {
            Text(rule.target.browserBundleID)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
            if let profile = rule.target.profile, !profile.isEmpty {
                Text("[\(profile)]")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
