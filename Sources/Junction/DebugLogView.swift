import SwiftUI

/// The single window shown by Junction at M1.
///
/// Shows every URL we've received, newest first, with the time and which
/// code path delivered it. Empty state tells the user how to get URLs to
/// appear (set Junction as default browser, click a link).
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
                Text("Junction logs every link macOS hands it.")
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
                Text("It'll appear here.")
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
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.url.absoluteString)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
            HStack(spacing: 8) {
                Label(entry.source.rawValue, systemImage: "arrow.down.right")
                    .labelStyle(.titleAndIcon)
                Text("•")
                Text(entry.receivedAt.formatted(date: .omitted, time: .standard))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview("With entries") {
    let log = URLLog.shared
    log.append(URL(string: "https://github.com/pkajaba/junction")!, source: .openURLs)
    log.append(URL(string: "https://news.ycombinator.com/item?id=123456")!, source: .appleEvent)
    return DebugLogView()
        .environmentObject(log)
        .frame(width: 560, height: 360)
}

#Preview("Empty") {
    DebugLogView()
        .environmentObject(URLLog.shared)
        .frame(width: 560, height: 360)
}
