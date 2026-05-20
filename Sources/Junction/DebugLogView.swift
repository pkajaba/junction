import SwiftUI

/// The single window shown by Junction at M1–M4.
///
/// Shows every URL we've received, newest first, with the time, which code
/// path delivered it, and the routing outcome (with reason: rule name or
/// picker). Empty state tells the user how to get URLs to appear.
struct DebugLogView: View {
    @EnvironmentObject private var log: URLLog
    @ObservedObject private var ruleStore = RuleStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let error = ruleStore.lastError {
                errorBanner(error)
            }
            Divider()
            content
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Received URLs")
                    .font(.headline)
                Text("^[\(ruleStore.rules.count) rule](inflect: true) loaded · picker is the fallback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("^[\(log.entries.count) entry](inflect: true)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Button("Clear", action: log.clear)
                .disabled(log.entries.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.08))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if log.entries.isEmpty {
            empty
        } else {
            list
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.circle")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No URLs yet")
                .font(.title3.weight(.semibold))
            VStack(spacing: 4) {
                Text("Set Junction as your default browser, then click a link anywhere.")
                Text("Matching rules route silently; the rest pop up a browser picker.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var list: some View {
        List(log.entries.reversed()) { entry in
            EntryRow(entry: entry)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// MARK: - Row

private struct EntryRow: View {
    let entry: URLLog.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.url.absoluteString)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
            if let rewritten = entry.rewritten {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(rewritten.absoluteString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            HStack(spacing: 10) {
                Label(entry.source.rawValue, systemImage: "arrow.down.right")
                separator
                Text(entry.receivedAt.formatted(date: .omitted, time: .standard))
                separator
                routingBadge
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var separator: some View {
        Text("•").foregroundStyle(.tertiary)
    }

    @ViewBuilder
    private var routingBadge: some View {
        switch entry.routing {
        case .pending:
            Label("routing…", systemImage: "ellipsis.circle")
        case .routed(let target, let reason):
            HStack(spacing: 4) {
                Label("→ \(target)", systemImage: "arrow.right.circle.fill")
                    .foregroundStyle(.green)
                Text(reasonText(reason))
                    .foregroundStyle(.tertiary)
            }
        case .failed(let reason):
            Label("failed: \(reason)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .unsupported:
            Label("unsupported scheme", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        case .cancelled:
            Label("cancelled", systemImage: "hand.raised.fill")
                .foregroundStyle(.secondary)
        }
    }

    private func reasonText(_ reason: URLLog.RouteReason) -> String {
        switch reason {
        case .picker:
            return "(picker)"
        case .rule(let name):
            return "(rule: \(name))"
        case .handoff(let name):
            return "(handoff → \(name))"
        }
    }
}

// MARK: - Previews

#Preview("With entries") {
    let log = URLLog.shared
    log.clear()
    let id1 = log.append(URL(string: "https://github.com/pkajaba/junction")!, source: .openURLs)
    let id2 = log.append(URL(string: "https://docs.google.com/document/d/abc")!, source: .openURLs)
    let id3 = log.append(URL(string: "https://news.ycombinator.com")!, source: .appleEvent)
    let id4 = log.append(URL(string: "https://example.com/failing")!, source: .openURLs)
    let id5 = log.append(URL(string: "mailto:hello@example.com")!, source: .openURLs)
    let id6 = log.append(URL(string: "https://example.com/cancelled")!, source: .openURLs)
    log.updateRouting(for: id1, to: .routed(to: "Chrome", via: .rule(name: "github → work Chrome")))
    log.updateRouting(for: id2, to: .routed(to: "Chrome", via: .rule(name: "Google Workspace")))
    log.updateRouting(for: id3, to: .routed(to: "Safari", via: .picker))
    log.updateRouting(for: id4, to: .failed(reason: "Safari not installed"))
    log.updateRouting(for: id5, to: .unsupported)
    log.updateRouting(for: id6, to: .cancelled)
    return DebugLogView()
        .environmentObject(log)
        .frame(width: 680, height: 420)
}

#Preview("Empty") {
    DebugLogView()
        .environmentObject(URLLog.shared)
        .frame(width: 680, height: 420)
}
