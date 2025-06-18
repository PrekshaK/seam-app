

import SwiftUI
import PencilKit

struct AddView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()

    var body: some View {
        VStack {
            CanvasView(canvasView: $canvasView, toolPicker: $toolPicker)
                .navigationBarTitle("Sketch", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Clear") {
                        canvasView.drawing = PKDrawing()
                    },
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
        .onAppear {
            setupToolPicker()
        }
    }

    private func setupToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .systemBackground
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        toolPicker.setVisible(true, forFirstResponder: uiView)
        toolPicker.addObserver(uiView)
        uiView.becomeFirstResponder()
    }
}

#Preview {
    NavigationView {
        AddView()
    }
}
