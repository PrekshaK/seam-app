import SwiftUI
import PencilKit

class CanvasHolder: ObservableObject {
    weak var canvasView: PKCanvasView?
    let toolPicker = PKToolPicker()

    func setup(_ canvas: PKCanvasView) {
        canvasView = canvas
        toolPicker.addObserver(canvas)
    }

    func undo() { canvasView?.undoManager?.undo() }
    func redo() { canvasView?.undoManager?.redo() }
    func clear() { canvasView?.drawing = PKDrawing() }

    func snapshotCropped(drawing: PKDrawing, padding: CGFloat = 32, scale: CGFloat = 2.0) -> UIImage? {
        guard let canvas = canvasView, let container = canvas.superview else { return nil }
        let containerBounds = container.bounds
        guard !containerBounds.isEmpty else { return nil }

        let cropRect: CGRect
        if drawing.bounds.isEmpty {
            cropRect = containerBounds
        } else {
            cropRect = drawing.bounds.insetBy(dx: -padding, dy: -padding).intersection(containerBounds)
        }

        let fullSize = CGSize(width: containerBounds.width * scale, height: containerBounds.height * scale)
        let fullImage = UIGraphicsImageRenderer(size: fullSize).image { ctx in
            ctx.cgContext.scaleBy(x: scale, y: scale)
            container.drawHierarchy(in: containerBounds, afterScreenUpdates: false)
        }

        let cropInPixels = CGRect(
            x: cropRect.minX * scale, y: cropRect.minY * scale,
            width: cropRect.width * scale, height: cropRect.height * scale
        )
        guard let cgImage = fullImage.cgImage?.cropping(to: cropInPixels) else { return fullImage }
        return UIImage(cgImage: cgImage)
    }

    func showTools() {
        guard let canvas = canvasView else { return }
        toolPicker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
    }

    func hideTools() {
        guard let canvas = canvasView else { return }
        toolPicker.setVisible(false, forFirstResponder: canvas)
        canvas.resignFirstResponder()
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
