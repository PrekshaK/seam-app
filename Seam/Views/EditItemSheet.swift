import SwiftUI
import SwiftData

struct EditItemSheet: View {
    let item: ClothingItem

    @State private var name: String
    @State private var category: ClothingCategory
    @State private var notes: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(item: ClothingItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _notes = State(initialValue: item.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Sketch preview
                    if let data = item.sketchData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.08), radius: 8)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)
                        TextField("Item name", text: $name)
                            .font(.custom("PatrickHand-Regular", size: 20))
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .lineLimit(3...6)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                    }

                    Button(action: save) {
                        Text("Save Changes")
                            .font(.custom("PatrickHand-Regular", size: 22))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.teal))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
            }
        }
    }

    private func save() {
        item.name = name.isEmpty ? "Untitled" : name
        item.category = category
        item.notes = notes.isEmpty ? nil : notes
        try? modelContext.save()
        dismiss()
    }
}
