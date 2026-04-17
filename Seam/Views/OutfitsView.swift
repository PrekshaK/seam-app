import SwiftUI
import SwiftData

struct OutfitsView: View {
    @Query(sort: \Closet.dateCreated) private var closets: [Closet]
    @State private var showCreateCloset = false
    @Environment(\.modelContext) private var modelContext

    private var closetService: ClosetService {
        ClosetService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                if closets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cabinet")
                            .font(.system(size: 56))
                            .foregroundColor(.teal.opacity(0.3))
                        Text("No closets yet")
                            .font(.custom("PatrickHand-Regular", size: 28))
                            .foregroundColor(.primary)
                        Text("Create a closet first, then start building outfits inside it.")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button(action: { showCreateCloset = true }) {
                            Label("Create a Closet", systemImage: "plus.circle.fill")
                                .font(.custom("PatrickHand-Regular", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.teal))
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(closets) { closet in
                                ClosetOutfitSection(closet: closet)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateCloset = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundColor(.teal)
                    }
                }
            }
            .sheet(isPresented: $showCreateCloset) {
                CreateClosetSheet(closetService: closetService)
            }
        }
    }
}

// MARK: - Closet Section with its outfits

struct ClosetOutfitSection: View {
    let closet: Closet
    @State private var showOutfitBuilder = false

    var sortedOutfits: [Outfit] {
        closet.outfits.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Closet header
            HStack {
                Image(systemName: closet.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.teal)
                Text(closet.name)
                    .font(.custom("PatrickHand-Regular", size: 24))
                    .foregroundColor(.primary)
                Spacer()
                NavigationLink(destination: ClosetDetailView(closet: closet)) {
                    Text("See all")
                        .font(.custom("PatrickHand-Regular", size: 16))
                        .foregroundColor(.teal)
                }
            }

            if sortedOutfits.isEmpty {
                Button(action: { showOutfitBuilder = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                        Text("Build your first outfit")
                            .font(.custom("PatrickHand-Regular", size: 18))
                    }
                    .foregroundColor(.teal.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(.teal.opacity(0.3))
                    )
                }
            } else {
                // Show up to 2 outfits + "see all"
                VStack(spacing: 12) {
                    ForEach(sortedOutfits.prefix(2)) { outfit in
                        NavigationLink(destination: OutfitDetailView(outfit: outfit)) {
                            OutfitRowCard(outfit: outfit)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if sortedOutfits.count > 2 {
                        NavigationLink(destination: ClosetDetailView(closet: closet)) {
                            Text("View all \(sortedOutfits.count) outfits →")
                                .font(.custom("PatrickHand-Regular", size: 16))
                                .foregroundColor(.teal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                    }

                    Button(action: { showOutfitBuilder = true }) {
                        Label("New Outfit", systemImage: "plus")
                            .font(.custom("PatrickHand-Regular", size: 17))
                            .foregroundColor(.teal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.teal.opacity(0.1)))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(color: .black.opacity(0.04), radius: 6))
        .fullScreenCover(isPresented: $showOutfitBuilder) {
            OutfitBuilderView(closet: closet)
        }
    }
}

#Preview {
    OutfitsView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
