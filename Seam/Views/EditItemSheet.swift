import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: ClothingItem
    var onSketchEdit: (ClothingItem) -> Void = { _ in }
    var onDelete: () -> Void = {}

    @State private var name: String
    @State private var category: ClothingCategory
    @State private var notes: String
    @State private var saved = false
    @State private var selectedClosetIds: Set<UUID>
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Closet.dateCreated) private var allClosets: [Closet]

    init(item: ClothingItem, onSketchEdit: @escaping (ClothingItem) -> Void = { _ in }, onDelete: @escaping () -> Void = {}) {
        self.item = item
        self.onSketchEdit = onSketchEdit
        self.onDelete = onDelete
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _notes = State(initialValue: item.notes ?? "")
        _selectedClosetIds = State(initialValue: Set(item.closets.map(\.id)))
    }

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Sketch preview
                    if let data = item.sketchData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.paperBeige)
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .blendMode(.multiply)
                            }
                            .frame(maxHeight: 260)
                            .cornerRadius(20)
                            .shadow(color: Color.warmShadow.opacity(0.08), radius: 10)

                            Button(action: { onSketchEdit(item) }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("Edit")
                                        .font(.custom("PatrickHand-Regular", size: 15))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.terracotta.opacity(0.85)))
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

                    // Delete button
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                            Text("Delete Item")
                                .font(.custom("PatrickHand-Regular", size: 18))
                        }
                        .foregroundColor(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.07)))
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationTitle(item.name.isEmpty ? item.category.rawValue : item.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete \"\(item.name.isEmpty ? item.category.rawValue : item.name)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
                onDelete()
            }
        } message: {
            Text("This item will be removed from all closets and outfits.")
        }
        .onChange(of: item) { _, newItem in
            name = newItem.name
            category = newItem.category
            notes = newItem.notes ?? ""
            selectedClosetIds = Set(newItem.closets.map(\.id))
            saved = false
        }
    }

    private func toggleCloset(_ closet: Closet) {
        if selectedClosetIds.contains(closet.id) {
            selectedClosetIds.remove(closet.id)
        } else {
            selectedClosetIds.insert(closet.id)
        }
    }

    private func save() {
        item.name = name.isEmpty ? "Untitled" : name
        item.category = category
        item.notes = notes.isEmpty ? nil : notes
        item.closets = allClosets.filter { selectedClosetIds.contains($0.id) }
        try? modelContext.save()
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            saved = false
        }
    }
}
