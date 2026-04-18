import SwiftUI
import SwiftData

struct ClosetDetailView: View {
    let closet: Closet

    @State private var showDeleteClosetConfirm = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var closetService: ClosetService {
        ClosetService(modelContext: modelContext)
    }

    var sortedOutfits: [Outfit] {
        closet.outfits.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if sortedOutfits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hanger")
                            .font(.system(size: 56))
                            .foregroundColor(.terracotta.opacity(0.3))
                        Text("No outfits yet")
                            .font(.custom("PatrickHand-Regular", size: 26))
                            .foregroundColor(.antiqueTeal)
                        Text("Start building your first outfit from your sketched items.")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.antiqueTeal.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        NavigationLink(destination: OutfitCanvasView(closet: closet)) {
                            Label("Build an Outfit", systemImage: "plus.circle.fill")
                                .font(.custom("PatrickHand-Regular", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.terracotta))
                        }
                    }
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 16) {
                        ForEach(sortedOutfits) { outfit in
                            NavigationLink(destination: OutfitCanvasView(closet: closet, existingOutfit: outfit)) {
                                OutfitRowCard(outfit: outfit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
        .background(Color("SoftBackground").ignoresSafeArea())
        .navigationTitle(closet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(destination: OutfitCanvasView(closet: closet)) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }

                Button(role: .destructive) {
                    showDeleteClosetConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .confirmationDialog("Delete \"\(closet.name)\"?", isPresented: $showDeleteClosetConfirm, titleVisibility: .visible) {
            Button("Delete Closet", role: .destructive) {
                closetService.deleteCloset(closet)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all outfits inside. Your clothing items won't be affected.")
        }
    }
}

// MARK: - Outfit Row Card

struct OutfitRowCard: View {
    let outfit: Outfit
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            // Outfit thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.antiqueTeal.opacity(0.15))
                    .frame(width: 72, height: 72)

                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "hanger")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .onAppear {
                if let data = outfit.thumbnailData, let img = UIImage(data: data) {
                    thumbnail = img
                } else {
                    thumbnail = outfit.renderThumbnail()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(outfit.name)
                    .font(.custom("PatrickHand-Regular", size: 20))
                    .foregroundColor(.white)
                Text("\(outfit.items.count) item\(outfit.items.count == 1 ? "" : "s")")
                    .font(.custom("PatrickHand-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.antiqueTeal))
        .shadow(color: Color.antiqueTeal.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}
