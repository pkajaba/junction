import SwiftUI
import AppKit

/// SwiftUI wrapper for `NSVisualEffectView` so we can use the same blur
/// material the system Settings windows and menus use. Backed by AppKit,
/// works on every supported macOS version.
///
/// `cornerRadius` rounds the blur via the view's `maskImage`. This is
/// required for `.behindWindow` blending: that blur is composited by the
/// WindowServer over the full window rect, so a SwiftUI `.clipShape` on the
/// hosting view can't round it — without the mask the panel's corners show
/// square blur. The mask is a capped (stretchable) rounded-rect image, so
/// it stays correct at any panel height. As a bonus, masking the blur also
/// rounds the alpha the borderless window's drop shadow is derived from.
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        view.maskImage = Self.maskImage(cornerRadius: cornerRadius)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.maskImage = Self.maskImage(cornerRadius: cornerRadius)
    }

    /// A rounded-rect mask whose centre is stretchable (cap insets), so a
    /// single small image masks the view at any size. `nil` for a zero
    /// radius — no masking, square as before.
    private static func maskImage(cornerRadius: CGFloat) -> NSImage? {
        guard cornerRadius > 0 else { return nil }
        let edge = cornerRadius * 2 + 1
        let image = NSImage(
            size: NSSize(width: edge, height: edge),
            flipped: false
        ) { rect in
            NSColor.black.setFill()
            NSBezierPath(
                roundedRect: rect,
                xRadius: cornerRadius,
                yRadius: cornerRadius
            ).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(
            top: cornerRadius, left: cornerRadius,
            bottom: cornerRadius, right: cornerRadius
        )
        image.resizingMode = .stretch
        return image
    }
}
