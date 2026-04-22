import UIKit
import SwiftUI
import PencilKit

// MARK: - SwiftUI wrapper for use in non-PencilKit views
struct PaperBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> PaperBackgroundUIView { PaperBackgroundUIView() }
    func updateUIView(_ uiView: PaperBackgroundUIView, context: Context) {}
}

class PaperBackgroundUIView: UIView {
    private var cachedTexture: UIImage?
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty, cachedTexture?.size != bounds.size else { return }
        cachedTexture = PaperTexture.image(size: bounds.size)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        cachedTexture?.draw(in: rect)
    }
}

// Deterministic LCG for reproducible texture across all render sizes
struct LCG {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(1 << 31)
    }
}

enum PaperTexture {
    static let baseColor = UIColor(red: 0.900, green: 0.850, blue: 0.752, alpha: 1.0)

    /// Renders the paper texture into the current graphics context, filling `rect`.
    static func render(in rect: CGRect, context ctx: CGContext) {
        var rng = LCG(state: 42)

        baseColor.setFill()
        ctx.fill(rect)

        // Fine grain
        let grainCount = Int(rect.width * rect.height * 0.07)
        for _ in 0..<grainCount {
            let x = rect.minX + rng.next() * rect.width
            let y = rect.minY + rng.next() * rect.height
            let s = rng.next() * 1.0 + 0.2
            UIColor(white: 0.40, alpha: CGFloat(rng.next() * 0.09 + 0.02)).setFill()
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s))
        }

        // Coarse flecks
        let fleckCount = Int(rect.width * rect.height * 0.003)
        for _ in 0..<fleckCount {
            let x = rect.minX + rng.next() * rect.width
            let y = rect.minY + rng.next() * rect.height
            let s = rng.next() * 2.5 + 0.8
            UIColor(white: 0.35, alpha: CGFloat(rng.next() * 0.06 + 0.01)).setFill()
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s * 0.6))
        }

        // Horizontal fibers
        ctx.setLineWidth(0.4)
        let fiberCount = Int(rect.height * 0.14)
        for _ in 0..<fiberCount {
            let y = rect.minY + rng.next() * rect.height
            let x1 = rect.minX + rng.next() * rect.width * 0.5
            let length = rng.next() * 90 + 20
            ctx.setStrokeColor(UIColor(white: 0.50, alpha: CGFloat(rng.next() * 0.05 + 0.01)).cgColor)
            ctx.move(to: CGPoint(x: x1, y: y))
            ctx.addLine(to: CGPoint(x: x1 + length, y: y + rng.next() * 1.2 - 0.6))
            ctx.strokePath()
        }

        // Vignette
        let colors = [UIColor(white: 0.75, alpha: 0.06).cgColor,
                      UIColor(white: 0.75, alpha: 0.00).cgColor,
                      UIColor(white: 0.75, alpha: 0.06).cgColor] as CFArray
        let locations: [CGFloat] = [0, 0.5, 1]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            ctx.drawLinearGradient(gradient, start: rect.origin, end: CGPoint(x: rect.minX, y: rect.maxY), options: [])
        }
    }

    /// Returns a UIImage of the texture at the given size.
    static func image(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererCtx in
            render(in: CGRect(origin: .zero, size: size), context: rendererCtx.cgContext)
        }
    }
}

extension PKDrawing {
    /// Crops to stroke bounds with padding, composited onto paper texture using multiply
    /// blend so the white PencilKit background becomes the paper color.
    func imageOnPaper(canvasSize: CGSize, padding: CGFloat = 32, scale: CGFloat = 2.0) -> UIImage {
        let cropRect = croppedRect(canvasSize: canvasSize, padding: padding)
        let drawingImage = image(from: cropRect, scale: scale)
        let pixelSize = drawingImage.size
        return UIGraphicsImageRenderer(size: pixelSize).image { rendererCtx in
            let ctx = rendererCtx.cgContext
            PaperTexture.render(in: CGRect(origin: .zero, size: pixelSize), context: ctx)
            // Multiply blend: white areas of the drawing become the paper color;
            // dark strokes remain dark.
            ctx.setBlendMode(.multiply)
            drawingImage.draw(at: .zero)
        }
    }

    /// Transparent PNG cropped tight to strokes — no background. Used for saving to sketchData.
    func transparentCropped(canvasSize: CGSize, padding: CGFloat = 32, scale: CGFloat = 2.0) -> UIImage {
        image(from: croppedRect(canvasSize: canvasSize, padding: padding), scale: scale)
    }

    private func croppedRect(canvasSize: CGSize, padding: CGFloat) -> CGRect {
        bounds.isEmpty
            ? CGRect(origin: .zero, size: canvasSize)
            : bounds.insetBy(dx: -padding, dy: -padding)
    }
}
