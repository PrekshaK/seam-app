import SwiftUI
import PencilKit

class CanvasHolder: ObservableObject {
    weak var canvasView: PKCanvasView?
    let toolPicker = PKToolPicker()

    func setup(_ canvas: PKCanvasView) {
        canvasView = canvas
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
    }

    func undo() { canvasView?.undoManager?.undo() }
    func redo() { canvasView?.undoManager?.redo() }
    func clear() { canvasView?.drawing = PKDrawing() }

    func showTools() {
        guard let canvas = canvasView else { return }
        toolPicker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
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
