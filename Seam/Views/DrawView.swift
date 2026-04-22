import SwiftUI
import PencilKit

struct DrawView: View {
    var editingItem: ClothingItem? = nil

    @State private var drawing: PKDrawing
    @StateObject private var canvasHolder = CanvasHolder()
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveSheet = false

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    init(editingItem: ClothingItem? = nil) {
        self.editingItem = editingItem
        if let item = editingItem,
           let data = item.drawingData,
           let loaded = try? PKDrawing(data: data) {
            _drawing = State(initialValue: loaded)
        } else {
            _drawing = State(initialValue: PKDrawing())
        }
    }

    private var isEditMode: Bool { editingItem != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
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

                    Button(action: { canvasHolder.clear() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red.opacity(0.7))
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
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color("SoftBackground"))

            GeometryReader { _ in
                PencilCanvasView(drawing: $drawing, holder: canvasHolder)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
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
            if !isEditMode { drawing = PKDrawing() }
            canvasHolder.showTools()
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveSketchSheet(
                drawing: drawing,
                canvasSize: canvasSize,
                onSave: { _ in
                    drawing = PKDrawing()
                    dismiss()
                }
            )
        }
    }

    private func handleCheckmark() {
        if isEditMode {
            saveEditedSketch()
        } else {
            if !drawing.strokes.isEmpty { showSaveSheet = true } else { dismiss() }
        }
    }

    private func saveEditedSketch() {
        guard let item = editingItem else { return }
        let sketchImage = drawing.transparentCropped(canvasSize: canvasSize)
        item.sketchData = sketchImage.pngData()
        item.drawingData = drawing.dataRepresentation()
        try? modelContext.save()
        dismiss()
    }
}
