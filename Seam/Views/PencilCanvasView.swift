import SwiftUI
import PencilKit

class CanvasHolder: ObservableObject {
    weak var canvasView: PKCanvasView?
    let toolPicker = PKToolPicker()

    func setup(_ canvas: PKCanvasView) {
        canvasView = canvas
        // Do NOT add observer here — showTools/hideTools manage the lifecycle
    }

    func undo() { canvasView?.undoManager?.undo() }
    func redo() { canvasView?.undoManager?.redo() }
    func clear() { canvasView?.drawing = PKDrawing() }

    // Renders the drawing onto a fixed 300×300 paper-texture thumbnail with the
    // drawing scaled and centered. Avoids any dependency on canvas frame or coordinate
    // offsets — drawing.bounds is used directly, then a transform centers it.
    func snapshotCropped(drawing: PKDrawing, padding: CGFloat = 32, scale: CGFloat = 2.0) -> UIImage? {
        let drawBounds = drawing.bounds
        guard !drawBounds.isEmpty else { return nil }

        let outputSize = CGSize(width: 300, height: 300)
        let available = CGSize(width: outputSize.width - 2 * padding,
                               height: outputSize.height - 2 * padding)
        let drawScale = min(available.width / drawBounds.width,
                            available.height / drawBounds.height)
        let scaledW = drawBounds.width * drawScale
        let scaledH = drawBounds.height * drawScale
        let offsetX = (outputSize.width - scaledW) / 2
        let offsetY = (outputSize.height - scaledH) / 2

        // Transform: move drawing origin to (0,0), scale it, then offset to center
        let transform = CGAffineTransform(
            a: drawScale, b: 0, c: 0, d: drawScale,
            tx: offsetX - drawBounds.minX * drawScale,
            ty: offsetY - drawBounds.minY * drawScale
        )
        var centered = drawing
        centered.transform(using: transform)

        var drawingImage: UIImage!
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            drawingImage = centered.image(from: CGRect(origin: .zero, size: outputSize), scale: scale)
        }

        return UIGraphicsImageRenderer(size: outputSize).image { ctx in
            PaperTexture.render(in: CGRect(origin: .zero, size: outputSize), context: ctx.cgContext)
            drawingImage.draw(at: .zero)
        }
    }

    func forceReloadDrawing(_ drawing: PKDrawing) {
        guard let canvas = canvasView else { return }
        // Empty-then-real assignment forces PencilKit to fully reset interaction state
        // (clears lasso selection overlay without touching tool picker state)
        canvas.drawing = PKDrawing()
        canvas.drawing = drawing
    }

    func setInteractionEnabled(_ enabled: Bool) {
        canvasView?.isUserInteractionEnabled = enabled
    }

    func showTools() {
        guard let canvas = canvasView else { return }
        toolPicker.addObserver(canvas)
        toolPicker.setVisible(true, forFirstResponder: canvas)
        DispatchQueue.main.async {
            canvas.becomeFirstResponder()
        }
    }

    func hideTools() {
        guard let canvas = canvasView else { return }
        toolPicker.setVisible(false, forFirstResponder: canvas)
        toolPicker.removeObserver(canvas)
        // Globally resign first responder — handles edge cases where the canvas
        // may not be the active first responder when this is called
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Paper background UIView

private class PaperTextureView: UIView {
    private var cachedTexture: UIImage?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty else { return }
        if cachedTexture?.size != bounds.size {
            cachedTexture = PaperTexture.image(size: bounds.size)
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        cachedTexture?.draw(in: rect)
    }
}

// MARK: - Canvas

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let holder: CanvasHolder

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.clipsToBounds = true

        let paper = PaperTextureView()
        paper.isOpaque = true
        paper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(paper)

        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.overrideUserInterfaceStyle = .light
        canvas.drawingPolicy = .anyInput
        canvas.isScrollEnabled = false
        canvas.delegate = context.coordinator
        canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(canvas)

        holder.setup(canvas)
        return container
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard let canvas = view.subviews.compactMap({ $0 as? PKCanvasView }).first else { return }
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PencilCanvasView
        init(_ parent: PencilCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
