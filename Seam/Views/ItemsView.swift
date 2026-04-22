import SwiftUI
import SwiftData

struct ItemsView: View {
    var onSketchNew: () -> Void = {}
    var onSketchEdit: (ClothingItem) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]
    @State private var selectedItem: ClothingItem?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var closetService: ClosetService { ClosetService(modelContext: modelContext) }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                if allItems.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedItem) {
                        ForEach(allItems) { item in
                            ItemSidebarRow(item: item, isSelected: selectedItem == item)
                                .tag(item)
                                .listRowBackground(selectedItem == item ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        if selectedItem == item { selectedItem = nil }
                                        closetService.deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        closetService.toggleFavorite(item)
                                    } label: {
                                        Label(
                                            item.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: item.isFavorite ? "heart.slash" : "heart"
                                        )
                                    }
                                    .tint(.pink)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onSketchNew) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.terracotta)
                    }
                }
            }
            .onChange(of: allItems) { _, newItems in
                if let sel = selectedItem, !newItems.contains(sel) {
                    selectedItem = nil
                }
            }
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item, onSketchEdit: onSketchEdit)
            } else {
                ZStack {
                    Color("SoftBackground").ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 52))
                            .foregroundColor(.antiqueTeal.opacity(0.2))
                        Text("Select an item to view")
                            .font(.custom("PatrickHand-Regular", size: 22))
                            .foregroundColor(.antiqueTeal.opacity(0.4))
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 48))
                .foregroundColor(.antiqueTeal.opacity(0.3))
            Text("No items yet")
                .font(.custom("PatrickHand-Regular", size: 22))
                .foregroundColor(.antiqueTeal)
            Button(action: onSketchNew) {
                Label("Sketch your first item", systemImage: "plus.circle.fill")
                    .font(.custom("PatrickHand-Regular", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.antiqueTeal))
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Item Sidebar Row

struct ItemSidebarRow: View {
    let item: ClothingItem
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.antiqueTeal : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.paperBeige)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.warmShadow.opacity(0.06), radius: 3)

                    if let data = item.sketchData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                            .frame(width: 48, height: 48)
                    } else {
                        CategoryIcon(category: item.category, size: 22)
                            .foregroundColor(.terracotta.opacity(0.5))
                    }

                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.antiqueTeal, lineWidth: 2)
                        .frame(width: 48, height: 48)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(item.name.isEmpty ? item.category.rawValue : item.name)
                            .font(.custom("PatrickHand-Regular", size: 19))
                            .foregroundColor(.antiqueTeal)
                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.pink)
                        }
                    }
                    Text(item.category.rawValue)
                        .font(.custom("PatrickHand-Regular", size: 14))
                        .foregroundColor(.antiqueTeal.opacity(0.55))
                }

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.vertical, 5)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Clothing Item Card (used in outfit picker)

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.paperBeige)
                    .shadow(color: Color.warmShadow.opacity(0.06), radius: 4)
                    .frame(width: 100, height: 100)

                if let data = item.sketchData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .frame(width: 100, height: 100)
                } else {
                    CategoryIcon(category: item.category, size: 36)
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
