import SwiftUI
import SwiftData

struct OutfitDetailView: View {
    let outfit: Outfit

    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var outfitService: OutfitService {
        OutfitService(modelContext: modelContext)
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if outfit.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hanger")
                            .font(.system(size: 48))
                            .foregroundColor(.teal.opacity(0.4))
                        Text("No items in this outfit yet")
                            .font(.custom("PatrickHand-Regular", size: 20))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(outfit.items) { item in
                            OutfitItemCard(item: item) {
                                outfitService.removeItem(item, from: outfit)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                if let notes = outfit.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(Color("SoftBackground").ignoresSafeArea())
        .navigationTitle(outfit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .confirmationDialog("Delete \"\(outfit.name)\"?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Outfit", role: .destructive) {
                outfitService.deleteOutfit(outfit)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This outfit will be removed. Your clothing items won't be affected.")
        }
    }
}

// MARK: - Outfit Item Card

struct OutfitItemCard: View {
    let item: ClothingItem
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 3)
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

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.8))
                        .background(Circle().fill(Color.white))
                }
                .offset(x: 4, y: -4)
            }

            Text(item.name.isEmpty ? item.category.rawValue : item.name)
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}
