import SwiftUI
import AppKit

// Sidebar row, section, and header-button views for the Rules tab.
// Split out of RulesSettingsView.swift to stay under SwiftLint's
// file_length budget.

// MARK: - Group section view
//
// `RuleGroup` itself lives in RulesGrouping.swift; the section view
// renders one of them, choosing the leading icon based on the group's
// `Icon` case (real browser/app icon, SF Symbol, or nothing for the
// flat "no grouping" case).

struct RuleGroupSection: View {
    let group: RuleGroup
    @Binding var selection: UUID?

    @State private var expanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if group.hasHeader {
                header
            }
            // Flat groups have no header, so the disclosure state is
            // ignored and rows render unconditionally.
            if expanded || !group.hasHeader {
                ForEach(group.rules) { rule in
                    RuleRow(rule: rule, isSelected: rule.id == selection) {
                        selection = rule.id
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        Button {
            expanded.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(expanded ? 0 : -90))
                    .foregroundStyle(.secondary)
                groupIcon
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
    }

    @ViewBuilder
    private var groupIcon: some View {
        switch group.icon {
        case .browser(let bundleID):
            BrowserIcon(bundleID: bundleID, size: 14)
        case .app(let bundleID):
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 11))
                    .frame(width: 14, height: 14)
                    .foregroundStyle(.tertiary)
            }
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 14, height: 14)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Header buttons (Round 2 ②)
//
// Two small circular buttons that live to the right of the "Rules"
// title. `+` is the primary action, hence the saturated fill. `−` is
// the secondary action — visible but understated, and disabled to 40%
// opacity when nothing is selected.

struct SidebarPlusButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(hovering ? Color.accentColor.opacity(0.85) : Color.accentColor)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Add rule")
        .accessibilityLabel("Add rule")
    }
}

struct SidebarMinusButton: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "minus")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(
                    Circle().fill(hovering && isEnabled
                                  ? Color.primary.opacity(0.06)
                                  : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    Circle().strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .onHover { hovering = $0 }
        .disabled(!isEnabled)
        .help("Delete selected rule")
        .accessibilityLabel("Delete selected rule")
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
        case .urlPrefix(let v):   urlPart = HostChipMatcher.chips(from: .urlPrefix(v))?.hosts.first ?? v
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
