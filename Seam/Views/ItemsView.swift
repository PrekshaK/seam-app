import SwiftUI
import SwiftData

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]
    @State private var selectedItem: ClothingItem?
    @State private var showDrawView = false
    @State private var isExpanded = true

    private var closetService: ClosetService { ClosetService(modelContext: modelContext) }
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed add button
                    Button(action: { showDrawView = true }) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.terracotta)
                            Text("Sketch new item")
                                .font(.custom("PatrickHand-Regular", size: 16))
                                .foregroundColor(.terracotta.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundColor(.terracotta.opacity(0.35))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Scrollable items section
                    ScrollView {
                        if !allItems.isEmpty {
                            VStack(spacing: 0) {
                                // Header
                                Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }) {
                                    HStack {
                                        Text("All Items")
                                            .font(.custom("PatrickHand-Regular", size: 22))
                                            .foregroundColor(.antiqueTeal)
                                        Text("(\(allItems.count))")
                                            .font(.custom("PatrickHand-Regular", size: 18))
                                            .foregroundColor(.antiqueTeal.opacity(0.6))
                                        Spacer()
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.antiqueTeal.opacity(0.6))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                }

                                if isExpanded {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(allItems) { item in
                                            ClothingItemCard(item: item)
                                                .onTapGesture { selectedItem = item }
                                                .contextMenu {
                                                    Button {
                                                        closetService.toggleFavorite(item)
                                                    } label: {
                                                        Label(
                                                            item.isFavorite ? "Unfavorite" : "Favorite",
                                                            systemImage: item.isFavorite ? "heart.slash" : "heart"
                                                        )
                                                    }
                                                    Button(role: .destructive) {
                                                        closetService.deleteItem(item)
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 24)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedItem) { item in
                EditItemSheet(item: item)
            }
            .fullScreenCover(isPresented: $showDrawView) {
                DrawView()
            }
        }
    }
}

// MARK: - Clothing Item Card

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.warmCard)
                    .shadow(color: Color.warmShadow.opacity(0.06), radius: 4)
                    .frame(width: 100, height: 100)

                if let data = item.sketchData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.terracotta.opacity(0.5))
                }

                if item.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.pink)
                                .padding(5)
                        }
                        Spacer()
                    }
                }

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.antiqueTeal, lineWidth: 4)
                    .frame(width: 100, height: 100)
            }

            Text(item.name.isEmpty ? item.category.rawValue : item.name)
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.antiqueTeal)
                .lineLimit(1)
        }
    }
}
