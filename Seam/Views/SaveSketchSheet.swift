import SwiftUI
import SwiftData
import PencilKit

struct SaveSketchSheet: View {
    let drawing: PKDrawing
    let canvasSize: CGSize
    let onSave: (ClothingItem) -> Void

    @State private var itemName = ""
    @State private var selectedCategory: ClothingCategory = .top
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sketch preview
                    if let preview = renderPreview() {
                        Image(uiImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(16)
                            .clipped()
                            .shadow(color: Color.warmShadow.opacity(0.08), radius: 8)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name (Optional)")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.antiqueTeal.opacity(0.6))

                        TextField("e.g., Blue Denim Jacket", text: $itemName)
                            .font(.custom("PatrickHand-Regular", size: 20))
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.antiqueTeal.opacity(0.6))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                            ForEach(ClothingCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }

                    // Save button
                    Button(action: saveItem) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                                Text("Save to My Closet")
                                    .font(.custom("PatrickHand-Regular", size: 22))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.terracotta))
                    }
                    .disabled(isSaving)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("Save Sketch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
            }
        }
    }

    private func renderPreview() -> UIImage? {
        drawing.imageOnPaper(canvasSize: canvasSize)
    }

    private func saveItem() {
        let sketchImage = drawing.transparentCropped(canvasSize: canvasSize)
        isSaving = true
        let item = ClothingItem(
            name: itemName.isEmpty ? "Untitled" : itemName,
            category: selectedCategory,
            sketchData: sketchImage.pngData(),
            drawingData: drawing.dataRepresentation()
        )
        modelContext.insert(item)
        try? modelContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isSaving = false
            dismiss()
            onSave(item)
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: ClothingCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                CategoryIcon(category: category, size: 22)
                Text(category.rawValue).font(.custom("PatrickHand-Regular", size: 14))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.terracotta : Color.gray.opacity(0.1)))
        }
    }
}
