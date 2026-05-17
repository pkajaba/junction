import SwiftUI

/// The single window shown by Junction at M1/M2.
///
/// Shows every URL we've received, newest first, with the time, which code
/// path delivered it, and (at M2) the routing outcome. Empty state tells
/// the user how to get URLs to appear.
struct DebugLogView: View {
    @EnvironmentObject private var log: URLLog

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
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
                Text("M2: every link is routed to Safari.")
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
                Text("Junction logs it here and opens it in Safari.")
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
        case .routed(let target):
            Label("→ \(target)", systemImage: "arrow.right.circle.fill")
                .foregroundStyle(.green)
        case .failed(let reason):
            Label("failed: \(reason)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .unsupported:
            Label("unsupported scheme", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("With entries") {
    let log = URLLog.shared
    log.clear()
    let id1 = log.append(URL(string: "https://github.com/pkajaba/junction")!, source: .openURLs)
    let id2 = log.append(URL(string: "https://news.ycombinator.com/item?id=123456")!, source: .appleEvent)
    let id3 = log.append(URL(string: "https://example.com/failing")!, source: .openURLs)
    let id4 = log.append(URL(string: "mailto:hello@example.com")!, source: .openURLs)
    log.updateRouting(for: id1, to: .routed(to: "Safari"))
    log.updateRouting(for: id2, to: .pending)
    log.updateRouting(for: id3, to: .failed(reason: "Safari not installed"))
    log.updateRouting(for: id4, to: .unsupported)
    return DebugLogView()
        .environmentObject(log)
        .frame(width: 620, height: 360)
}

#Preview("Empty") {
    DebugLogView()
        .environmentObject(URLLog.shared)
        .frame(width: 620, height: 360)
}
