import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: ClothingItem

    @State private var name: String
    @State private var category: ClothingCategory
    @State private var notes: String
    @State private var saved = false
    @State private var showEditSketch = false

    @Environment(\.modelContext) private var modelContext

    init(item: ClothingItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _notes = State(initialValue: item.notes ?? "")
    }

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Sketch preview
                    if let data = item.sketchData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 260)
                                .background(Color.paperBeige)
                                .cornerRadius(20)
                                .shadow(color: Color.warmShadow.opacity(0.08), radius: 10)

                            Button(action: { showEditSketch = true }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Edit Sketch")
                                        .font(.custom("PatrickHand-Regular", size: 15))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.antiqueTeal.opacity(0.85)))
                            }
                            .padding(12)
                        }
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.antiqueTeal.opacity(0.6))
                        TextField("Item name", text: $name)
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
                                    isSelected: category == cat,
                                    action: { category = cat }
                                )
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

                    Button(action: save) {
                        HStack(spacing: 8) {
                            Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 18))
                            Text(saved ? "Saved!" : "Save Changes")
                                .font(.custom("PatrickHand-Regular", size: 22))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(saved ? Color.antiqueTeal : Color.terracotta))
                        .animation(.easeInOut(duration: 0.2), value: saved)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationTitle(item.name.isEmpty ? item.category.rawValue : item.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showEditSketch) {
            DrawView(editingItem: item)
        }
        .onChange(of: item) { _, newItem in
            name = newItem.name
            category = newItem.category
            notes = newItem.notes ?? ""
            saved = false
        }
    }

    private func save() {
        item.name = name.isEmpty ? "Untitled" : name
        item.category = category
        item.notes = notes.isEmpty ? nil : notes
        try? modelContext.save()
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            saved = false
        }
    }
}
