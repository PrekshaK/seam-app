import SwiftUI
import SwiftData

struct ClosetDetailView: View {
    let closet: Closet

    @State private var showOutfitBuilder = false
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
                            .foregroundColor(.teal.opacity(0.3))
                        Text("No outfits yet")
                            .font(.custom("PatrickHand-Regular", size: 26))
                            .foregroundColor(.primary)
                        Text("Start building your first outfit from your sketched items.")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: { showOutfitBuilder = true }) {
                            Label("Build an Outfit", systemImage: "plus.circle.fill")
                                .font(.custom("PatrickHand-Regular", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.teal))
                        }
                    }
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 16) {
                        ForEach(sortedOutfits) { outfit in
                            NavigationLink(destination: OutfitDetailView(outfit: outfit)) {
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
                Button(action: { showOutfitBuilder = true }) {
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
        .fullScreenCover(isPresented: $showOutfitBuilder) {
            OutfitBuilderView(closet: closet)
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

    var body: some View {
        HStack(spacing: 16) {
            // Sketch previews (up to 3)
            HStack(spacing: -20) {
                ForEach(outfit.items.prefix(3)) { item in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 52, height: 52)
                            .shadow(color: .black.opacity(0.08), radius: 3)
                        if let data = item.sketchData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.teal.opacity(0.6))
                        }
                    }
                }
                if outfit.items.count > 3 {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Text("+\(outfit.items.count - 3)")
                            .font(.custom("PatrickHand-Regular", size: 16))
                            .foregroundColor(.teal)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(outfit.name)
                    .font(.custom("PatrickHand-Regular", size: 22))
                    .foregroundColor(.primary)
                Text("\(outfit.items.count) item\(outfit.items.count == 1 ? "" : "s")")
                    .font(.custom("PatrickHand-Regular", size: 16))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}
