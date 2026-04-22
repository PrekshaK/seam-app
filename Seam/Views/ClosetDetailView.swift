import SwiftUI
import SwiftData

struct ClosetDetailView: View {
    let closet: Closet

    @State private var showDeleteClosetConfirm = false
    @State private var showNewOutfit = false
    @State private var editingOutfit: Outfit? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var closetService: ClosetService {
        ClosetService(modelContext: modelContext)
    }

    var sortedOutfits: [Outfit] {
        closet.outfits.sorted { $0.dateCreated > $1.dateCreated }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            ScrollView {
                if sortedOutfits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hanger")
                            .font(.system(size: 56))
                            .foregroundColor(.antiqueTeal.opacity(0.3))
                        Text("No outfits yet")
                            .font(.custom("PatrickHand-Regular", size: 26))
                            .foregroundColor(.antiqueTeal)
                        Text("Start building your first outfit from your sketched items.")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.antiqueTeal.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: { showNewOutfit = true }) {
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
                    LazyVGrid(columns: columns, spacing: 28) {
                        ForEach(sortedOutfits) { outfit in
                            Button(action: { editingOutfit = outfit }) {
                                OutfitPolaroidCard(outfit: outfit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(closet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showNewOutfit = true }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundColor(.terracotta)
                }

                Button(role: .destructive) {
                    showDeleteClosetConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .fullScreenCover(isPresented: $showNewOutfit) {
            OutfitCanvasView(closet: closet)
        }
        .fullScreenCover(item: $editingOutfit) { outfit in
            OutfitCanvasView(closet: closet, existingOutfit: outfit)
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

// MARK: - Polaroid Card

struct OutfitPolaroidCard: View {
    let outfit: Outfit
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            // Photo area
            ZStack {
                Color.paperBeige

                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Image(systemName: "hanger")
                        .font(.system(size: 36))
                        .foregroundColor(.antiqueTeal.opacity(0.25))
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Label strip
            VStack(spacing: 3) {
                Text(outfit.name)
                    .font(.custom("PatrickHand-Regular", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(outfit.items.count) item\(outfit.items.count == 1 ? "" : "s")")
                    .font(.custom("PatrickHand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.terracotta.opacity(0.72))
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .shadow(color: Color.warmShadow.opacity(0.18), radius: 8, x: 0, y: 4)
        .padding(.vertical, 6)
        .onAppear {
            if let data = outfit.thumbnailData, let img = UIImage(data: data) {
                thumbnail = img
            } else {
                thumbnail = outfit.renderThumbnail()
            }
        }
    }
}
