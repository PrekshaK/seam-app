import SwiftUI
import PencilKit

struct DrawView: View {
    @State private var drawing = PKDrawing()
    @StateObject private var canvasHolder = CanvasHolder()
    @State private var canvasSize: CGSize = .zero
    @State private var showSaveSheet = false

    @Environment(\.dismiss) var dismiss

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

                Text("Sketch Item")
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

                    Button(action: {
                        if !drawing.strokes.isEmpty { showSaveSheet = true } else { dismiss() }
                    }) {
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
            drawing = PKDrawing()
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
}
