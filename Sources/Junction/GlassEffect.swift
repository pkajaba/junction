import SwiftUI

/// View modifier that applies Liquid Glass on macOS 26 (Tahoe) and falls
/// back to the standard material/clip/border treatment on macOS 14–15.
///
/// Why a separate file: keeps the `#available` branches out of the picker
/// layout code, which would otherwise get noisy. The picker calls
/// `.junctionPickerBackground(...)` and doesn't care which path it takes.
extension View {

    /// Picker window background: glassy on macOS 26+, frosted material below.
    @ViewBuilder
    func junctionPickerBackground(cornerRadius: CGFloat, optionHeld: Bool) -> some View {
        if #available(macOS 26.0, *) {
            self
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay {
                    if optionHeld {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.7), lineWidth: 2)
                    }
                }
        } else {
            self
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            optionHeld
                                ? Color.accentColor.opacity(0.7)
                                : Color(nsColor: .separatorColor).opacity(0.6),
                            lineWidth: optionHeld ? 2 : 0.5
                        )
                )
        }
    }

    /// Browser tile selected state: tinted glass on macOS 26+, accent
    /// fill + stroke on older releases.
    @ViewBuilder
    func junctionTileBackground(isSelected: Bool, cornerRadius: CGFloat = 10) -> some View {
        if #available(macOS 26.0, *) {
            self
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .glassEffect(
                                .regular.tint(Color.accentColor.opacity(0.35)),
                                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            )
                    }
                }
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
                )
        }
    }
}
