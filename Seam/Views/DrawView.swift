import SwiftUI
import PencilKit

struct DrawView: View {
    var editingItem: ClothingItem? = nil
    var isActive: Bool = true
    var onClose: (() -> Void)? = nil

    @State private var drawing = PKDrawing()
    @StateObject private var canvasHolder = CanvasHolder()
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveSheet = false
    @State private var pendingSnapshot: UIImage? = nil
    @State private var canvasId = UUID()
    @State private var isResizing = false
    @State private var resizeRect: CGRect = .zero
    @State private var drawingBeforeResize = PKDrawing()

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    private var isEditMode: Bool { editingItem != nil }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func loadDrawing() {
        let newDrawing: PKDrawing
        if let item = editingItem,
           let data = item.drawingData,
           let loaded = try? PKDrawing(data: data) {
            newDrawing = loaded
        } else {
            newDrawing = PKDrawing()
        }
        drawing = newDrawing
        // Changing canvasId forces SwiftUI to tear down and recreate PKCanvasView,
        // guaranteeing a fresh canvas with no prior lasso/interaction state.
        canvasId = UUID()
        if isActive {
            DispatchQueue.main.async { canvasHolder.showTools() }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if isResizing {
                    Button(action: cancelResize) {
                        Text("Cancel")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.antiqueTeal)
                    }
                    .frame(minWidth: 60, alignment: .leading)

                    Spacer()

                    Text("Resize")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal)

                    Spacer()

                    Button(action: applyResize) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.terracotta)
                    }
                    .frame(minWidth: 60, alignment: .trailing)
                } else {
                    Button(action: { close() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.antiqueTeal)
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    Text(isEditMode ? "Edit Sketch" : "Sketch Item")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: { canvasHolder.undo() }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.antiqueTeal)
                                .frame(width: 36, height: 36)
                        }
                        .disabled(drawing.strokes.isEmpty)
                        .opacity(drawing.strokes.isEmpty ? 0.3 : 1.0)

                        Button(action: { canvasHolder.redo() }) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.antiqueTeal)
                                .frame(width: 36, height: 36)
                        }
                        .disabled(drawing.strokes.isEmpty)
                        .opacity(drawing.strokes.isEmpty ? 0.3 : 1.0)

                        Button(action: { drawing = PKDrawing() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                                .frame(width: 36, height: 36)
                        }
                        .disabled(drawing.strokes.isEmpty)
                        .opacity(drawing.strokes.isEmpty ? 0.3 : 1.0)

                        Button(action: enterResize) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.antiqueTeal)
                                .frame(width: 36, height: 36)
                        }
                        .disabled(drawing.strokes.isEmpty)
                        .opacity(drawing.strokes.isEmpty ? 0.3 : 1.0)

                        Button(action: handleCheckmark) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.terracotta)
                        }
                        .disabled(drawing.strokes.isEmpty)
                        .opacity(drawing.strokes.isEmpty ? 0.3 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color("SoftBackground"))

            GeometryReader { _ in
                PencilCanvasView(drawing: $drawing, holder: canvasHolder)
                    .id(canvasId)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        if isResizing {
                            ResizeOverlay(rect: $resizeRect)
                        }
                    }
                    .shadow(color: Color.warmShadow.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .background(GeometryReader { inner in
                        Color.clear.onAppear { canvasSize = inner.size }
                    })
            }
        }
        .background(Color("SoftBackground").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            loadDrawing()
        }
        .onDisappear {
            canvasHolder.hideTools()
        }
        .onChange(of: isActive) { _, active in
            if active {
                loadDrawing()
            } else {
                isResizing = false
                canvasHolder.hideTools()
            }
        }
        .onChange(of: editingItem?.id) { _, _ in
            loadDrawing()
        }
        .onChange(of: resizeRect) { _, newRect in
            guard isResizing else { return }
            liveResizePreview(newRect)
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveSketchSheet(
                drawing: drawing,
                canvasSize: canvasSize,
                snapshot: pendingSnapshot,
                onSave: { _ in
                    drawing = PKDrawing()
                    close()
                }
            )
        }
    }

    private func handleCheckmark() {
        if isEditMode {
            saveEditedSketch()
        } else {
            if !drawing.strokes.isEmpty {
                pendingSnapshot = canvasHolder.snapshotCropped(drawing: drawing)
                showSaveSheet = true
            } else {
                close()
            }
        }
    }

    private func enterResize() {
        guard !drawing.strokes.isEmpty else { return }
        drawingBeforeResize = drawing
        resizeRect = drawing.bounds.insetBy(dx: -8, dy: -8)
        canvasHolder.hideTools()
        canvasHolder.setInteractionEnabled(false)
        isResizing = true
    }

    private func liveResizePreview(_ newRect: CGRect) {
        let orig = drawingBeforeResize.bounds.insetBy(dx: -8, dy: -8)
        guard orig.width > 0, orig.height > 0 else { return }
        let sx = newRect.width / orig.width
        let sy = newRect.height / orig.height
        let tx = newRect.minX - orig.minX * sx
        let ty = newRect.minY - orig.minY * sy
        var newDrawing = drawingBeforeResize
        newDrawing.transform(using: CGAffineTransform(a: sx, b: 0, c: 0, d: sy, tx: tx, ty: ty))
        drawing = newDrawing
    }

    private func applyResize() {
        // drawing already reflects the live preview
        exitResize()
    }

    private func cancelResize() {
        drawing = drawingBeforeResize
        exitResize()
    }

    private func exitResize() {
        canvasHolder.setInteractionEnabled(true)
        isResizing = false
        canvasHolder.showTools()
    }

    private func saveEditedSketch() {
        guard let item = editingItem else { return }
        let baked = drawing.bakingAdaptiveColors(to: .light)
        item.sketchData = baked.centeredTransparent()?.pngData()
        item.drawingData = baked.dataRepresentation()
        try? modelContext.save()
        close()
    }
}
