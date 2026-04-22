import SwiftUI
import SwiftData
import PencilKit

struct SaveSketchSheet: View {
    let drawing: PKDrawing
    let canvasSize: CGSize
    let onSave: (ClothingItem) -> Void

    @State private var itemName = ""
    @State private var selectedCategory: ClothingCategory = .top
    @State private var notes = ""
    @State private var selectedClosetIds: Set<UUID> = []
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Closet.dateCreated) private var allClosets: [Closet]

    private var preview: UIImage? { drawing.transparentCropped(canvasSize: canvasSize) }

    var body: some View {
        NavigationView {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Sketch preview
                        if let uiImage = preview {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.paperBeige)
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .blendMode(.multiply)
                            }
                            .frame(maxHeight: 240)
                            .cornerRadius(20)
                            .shadow(color: Color.warmShadow.opacity(0.08), radius: 10)
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
                                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                                    CategoryButton(
                                        category: cat,
                                        isSelected: selectedCategory == cat,
                                        action: { selectedCategory = cat }
                                    )
                                }
                            }
                        }

                        // Closets
                        if !allClosets.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Closets")
                                    .font(.custom("PatrickHand-Regular", size: 16))
                                    .foregroundColor(.antiqueTeal.opacity(0.6))
                                VStack(spacing: 6) {
                                    ForEach(allClosets) { closet in
                                        Button(action: { toggleCloset(closet) }) {
                                            HStack(spacing: 12) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.antiqueTeal.opacity(0.12))
                                                        .frame(width: 34, height: 34)
                                                    Image(systemName: closet.icon)
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.antiqueTeal)
                                                }
                                                Text(closet.name)
                                                    .font(.custom("PatrickHand-Regular", size: 18))
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                if selectedClosetIds.contains(closet.id) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.terracotta)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.gray.opacity(0.3))
                                                }
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.07)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.custom("PatrickHand-Regular", size: 16))
                                .foregroundColor(.antiqueTeal.opacity(0.6))
                            TextField("Add notes...", text: $notes, axis: .vertical)
                                .font(.custom("PatrickHand-Regular", size: 18))
                                .lineLimit(3...6)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
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
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Save Sketch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.terracotta)
                }
            }
        }
    }

    private func toggleCloset(_ closet: Closet) {
        if selectedClosetIds.contains(closet.id) {
            selectedClosetIds.remove(closet.id)
        } else {
            selectedClosetIds.insert(closet.id)
        }
    }

    private func saveItem() {
        let sketchImage = drawing.transparentCropped(canvasSize: canvasSize)
        isSaving = true
        let item = ClothingItem(
            name: itemName.isEmpty ? "Untitled" : itemName,
            category: selectedCategory,
            sketchData: sketchImage.pngData(),
            drawingData: drawing.dataRepresentation(),
            notes: notes.isEmpty ? nil : notes,
            closets: allClosets.filter { selectedClosetIds.contains($0.id) }
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
