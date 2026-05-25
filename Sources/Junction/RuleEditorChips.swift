import SwiftUI
import AppKit

// Host-chip helper views used by the rule editor. Lives in its own file
// so `RuleEditorView.swift` stays under SwiftLint's file_length budget.

// MARK: - Host chip pill

struct HostChipView: View {
    let host: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HostGlyph(host: host)
            Text(host)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

// MARK: - Add chip input

struct AddChipField: View {
    @Binding var text: String
    let onCommit: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("Add host", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .focused($isFocused)
                .onSubmit { onCommit(text) }
                .onChange(of: text) { _, newValue in
                    // Commit on space or comma to match typical chip-input UX.
                    if newValue.hasSuffix(" ") || newValue.hasSuffix(",") {
                        let stripped = String(newValue.dropLast())
                        onCommit(stripped)
                    }
                }
                .frame(minWidth: 100, maxWidth: 160)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 3])
                )
                .foregroundStyle(Color(nsColor: .separatorColor))
        )
    }
}

// MARK: - Host glyph (colored circle with first letter)

struct HostGlyph: View {
    let host: String

    private var firstChar: String {
        String(host.prefix(1)).uppercased()
    }

    private var tint: Color {
        let hash = host.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.65)
    }

    var body: some View {
        Text(firstChar.isEmpty ? "?" : firstChar)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 12, height: 12)
            .background(tint)
            .clipShape(Circle())
    }
}

// MARK: - Simple wrapping HStack for the chip flow

/// A minimal flow layout — wraps children to a new row when they exceed
/// the container width. SwiftUI's `Layout` protocol makes this
/// straightforward.
struct WrappingHStack: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let arrangement = arrange(subviews: subviews, in: width)
        let height = arrangement.last.map { $0.maxY } ?? 0
        return CGSize(width: width.isFinite ? width : arrangement.maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, in: bounds.width)
        for (index, frame) in arrangement.frames.enumerated() {
            let proposal = ProposedViewSize(width: frame.width, height: frame.height)
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                  proposal: proposal)
        }
    }

    private struct Arrangement {
        var frames: [CGRect] = []
        var maxWidth: CGFloat = 0
        var last: CGRect? { frames.last }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> Arrangement {
        var result = Arrangement()
        var cursorX: CGFloat = 0
        var cursorY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let usableWidth = width.isFinite ? width : .infinity

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if cursorX > 0, cursorX + size.width > usableWidth {
                cursorX = 0
                cursorY += lineHeight + lineSpacing
                lineHeight = 0
            }
            let frame = CGRect(x: cursorX, y: cursorY, width: size.width, height: size.height)
            result.frames.append(frame)
            result.maxWidth = max(result.maxWidth, frame.maxX)
            cursorX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return result
    }
}
