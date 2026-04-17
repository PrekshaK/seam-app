import SwiftUI
import SwiftData

struct OutfitBuilderView: View {
    let closet: Closet

    @State private var outfitName = ""
    @State private var selectedItems: Set<UUID> = []

    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var outfitService: OutfitService {
        OutfitService(modelContext: modelContext)
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Outfit name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Outfit Name")
                        .font(.custom("PatrickHand-Regular", size: 16))
                        .foregroundColor(.secondary)
                    TextField("e.g., Monday Fit", text: $outfitName)
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider()

                // Selected count
                if !selectedItems.isEmpty {
                    HStack {
                        Text("\(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s") selected")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.teal)
                        Spacer()
                        Button("Clear") { selectedItems.removeAll() }
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                // All Items picker
                if allItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 48))
                            .foregroundColor(.teal.opacity(0.4))
                        Text("No items yet")
                            .font(.custom("PatrickHand-Regular", size: 22))
                            .foregroundColor(.secondary)
                        Text("Sketch some clothes first, then come back to build an outfit.")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(allItems) { item in
                                ItemPickerCard(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id),
                                    onTap: {
                                        if selectedItems.contains(item.id) {
                                            selectedItems.remove(item.id)
                                        } else {
                                            selectedItems.insert(item.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }

                // Save button
                VStack {
                    Divider()
                    Button(action: save) {
                        Text("Create Outfit")
                            .font(.custom("PatrickHand-Regular", size: 22))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canSave ? Color.teal : Color.gray.opacity(0.4))
                            )
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color("SoftBackground"))
            }
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("Build an Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
            }
        }
    }

    private var canSave: Bool {
        !outfitName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedItems.isEmpty
    }

    private func save() {
        let chosen = allItems.filter { selectedItems.contains($0.id) }
        outfitService.createOutfit(name: outfitName.trimmingCharacters(in: .whitespaces), closet: closet, items: chosen)
        dismiss()
    }
}

// MARK: - Item Picker Card

struct ItemPickerCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: isSelected ? Color.teal.opacity(0.3) : Color.black.opacity(0.06), radius: isSelected ? 6 : 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(isSelected ? Color.teal : Color.clear, lineWidth: 2.5)
                            )
                            .frame(width: 100, height: 100)

                        if let data = item.sketchData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 32))
                                .foregroundColor(.teal.opacity(0.5))
                        }
                    }

                    Text(item.name.isEmpty ? item.category.rawValue : item.name)
                        .font(.custom("PatrickHand-Regular", size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.teal)
                        .background(Circle().fill(Color.white).padding(2))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
