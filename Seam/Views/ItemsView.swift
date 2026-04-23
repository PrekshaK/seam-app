import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case allItems
    case closet(Closet)
}

struct ItemsView: View {
    var onSketchNew: () -> Void = {}
    var onSketchEdit: (ClothingItem) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]
    @Query(sort: \Closet.dateCreated) private var closets: [Closet]

    @State private var sidebarSelection: SidebarSelection? = .allItems
    @State private var selectedItem: ClothingItem? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var filterCategory: ClothingCategory? = nil
    @State private var showCreateCloset = false

    private var closetService: ClosetService { ClosetService(modelContext: modelContext) }

    private var displayedItems: [ClothingItem] {
        let base: [ClothingItem]
        if case .closet(let c) = sidebarSelection {
            base = c.items.sorted { $0.dateAdded > $1.dateAdded }
        } else {
            base = Array(allItems)
        }
        guard let cat = filterCategory else { return base }
        return base.filter { $0.category == cat }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(item: $selectedItem) { item in
            NavigationView {
                ItemDetailView(
                    item: item,
                    onSketchEdit: { editItem in
                        selectedItem = nil
                        onSketchEdit(editItem)
                    },
                    onDelete: { selectedItem = nil },
                    onDone: { selectedItem = nil }
                )
            }
        }
        .sheet(isPresented: $showCreateCloset) {
            CreateClosetSheet(closetService: closetService)
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()
            List(selection: $sidebarSelection) {
                AllItemsSidebarRow(count: allItems.count, isSelected: sidebarSelection == .allItems)
                    .tag(SidebarSelection.allItems)
                    .listRowBackground(sidebarSelection == .allItems ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))

                ForEach(closets) { closet in
                    ClosetSidebarRow(closet: closet, isSelected: sidebarSelection == .closet(closet))
                        .tag(SidebarSelection.closet(closet))
                        .listRowBackground(sidebarSelection == .closet(closet) ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if sidebarSelection == .closet(closet) { sidebarSelection = .allItems }
                                closetService.deleteCloset(closet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .tint(.antiqueTeal)
        }
        .navigationTitle("Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateCloset = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.antiqueTeal)
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if case .closet(let closet) = sidebarSelection {
            ClosetItemsView(
                closet: closet,
                filterCategory: $filterCategory,
                allItems: allItems,
                onItemTap: { selectedItem = $0 },
                onSketchNew: onSketchNew,
                closetService: closetService
            )
        } else {
            AllItemsDetailView(
                items: displayedItems,
                allItemsEmpty: allItems.isEmpty,
                filterCategory: $filterCategory,
                onItemTap: { selectedItem = $0 },
                onSketchNew: onSketchNew,
                closetService: closetService
            )
        }
    }
}

// MARK: - All Items Detail

struct AllItemsDetailView: View {
    let items: [ClothingItem]
    let allItemsEmpty: Bool
    @Binding var filterCategory: ClothingCategory?
    let onItemTap: (ClothingItem) -> Void
    let onSketchNew: () -> Void
    let closetService: ClosetService

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 16)]

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            if allItemsEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        Button(action: onSketchNew) { AddItemCard() }

                        ForEach(items) { item in
                            Button(action: { onItemTap(item) }) {
                                ClothingItemCard(item: item)
                            }
                            .contextMenu {
                                Button {
                                    closetService.toggleFavorite(item)
                                } label: {
                                    Label(item.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: item.isFavorite ? "heart.slash" : "heart")
                                }
                                Button(role: .destructive) {
                                    closetService.deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("All Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filterMenu
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Button { filterCategory = nil } label: {
                Label("All", systemImage: filterCategory == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(ClothingCategory.allCases, id: \.self) { cat in
                Button { filterCategory = cat } label: {
                    Label(cat.rawValue, systemImage: filterCategory == cat ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: filterCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 17))
                .foregroundColor(filterCategory == nil ? .antiqueTeal : .terracotta)
        }
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
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.terracotta))
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Closet Items Detail

struct ClosetItemsView: View {
    let closet: Closet
    @Binding var filterCategory: ClothingCategory?
    let allItems: [ClothingItem]
    let onItemTap: (ClothingItem) -> Void
    let onSketchNew: () -> Void
    let closetService: ClosetService

    @Environment(\.modelContext) private var modelContext
    @State private var showItemPicker = false

    private var displayedItems: [ClothingItem] {
        let base = closet.items.sorted { $0.dateAdded > $1.dateAdded }
        guard let cat = filterCategory else { return base }
        return base.filter { $0.category == cat }
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 16)]

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            if closet.items.isEmpty {
                closetEmptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayedItems) { item in
                            Button(action: { onItemTap(item) }) {
                                ClothingItemCard(item: item)
                            }
                            .contextMenu {
                                Button {
                                    closetService.toggleFavorite(item)
                                } label: {
                                    Label(item.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: item.isFavorite ? "heart.slash" : "heart")
                                }
                                Button(role: .destructive) {
                                    closet.items.removeAll { $0.id == item.id }
                                    try? modelContext.save()
                                } label: {
                                    Label("Remove from Closet", systemImage: "folder.badge.minus")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle(closet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                filterMenu
                Button(action: { showItemPicker = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.terracotta)
                }
            }
        }
        .sheet(isPresented: $showItemPicker) {
            ItemPickerSheet(
                allItems: allItems,
                selectedIds: Set(closet.items.map(\.id)),
                onToggle: { item in
                    if closet.items.contains(where: { $0.id == item.id }) {
                        closet.items.removeAll { $0.id == item.id }
                    } else {
                        closet.items.append(item)
                    }
                    try? modelContext.save()
                }
            )
        }
    }

    private var filterMenu: some View {
        Menu {
            Button { filterCategory = nil } label: {
                Label("All", systemImage: filterCategory == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(ClothingCategory.allCases, id: \.self) { cat in
                Button { filterCategory = cat } label: {
                    Label(cat.rawValue, systemImage: filterCategory == cat ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: filterCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 17))
                .foregroundColor(filterCategory == nil ? .antiqueTeal : .terracotta)
        }
    }

    private var closetEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.antiqueTeal.opacity(0.3))
            Text("No items in this closet")
                .font(.custom("PatrickHand-Regular", size: 22))
                .foregroundColor(.antiqueTeal)
            Button(action: { showItemPicker = true }) {
                Label("Add Items", systemImage: "plus.circle.fill")
                    .font(.custom("PatrickHand-Regular", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.terracotta))
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Add Item Card

struct AddItemCard: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.terracotta.opacity(0.4))
                    .frame(width: 100, height: 100)
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.terracotta.opacity(0.5))
            }
            Text("New Item")
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.terracotta.opacity(0.6))
                .lineLimit(1)
        }
    }
}

// MARK: - All Items Sidebar Row

struct AllItemsSidebarRow: View {
    let count: Int
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.antiqueTeal : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.antiqueTeal.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.antiqueTeal)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("All Items")
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.antiqueTeal)
                    Text("\(count) item\(count == 1 ? "" : "s")")
                        .font(.custom("PatrickHand-Regular", size: 14))
                        .foregroundColor(.antiqueTeal.opacity(0.55))
                }

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.vertical, 6)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Closet Sidebar Row

struct ClosetSidebarRow: View {
    let closet: Closet
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.antiqueTeal : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.antiqueTeal)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.antiqueTeal.opacity(0.3), radius: 4, x: 0, y: 2)
                    Image(systemName: closet.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(closet.name)
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.antiqueTeal)
                    Text("\(closet.items.count) item\(closet.items.count == 1 ? "" : "s")")
                        .font(.custom("PatrickHand-Regular", size: 14))
                        .foregroundColor(.antiqueTeal.opacity(0.55))
                }

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.vertical, 6)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Create Closet Sheet

struct CreateClosetSheet: View {
    let closetService: ClosetService

    @State private var closetName = ""
    @State private var selectedIcon = "cabinet.fill"
    @Environment(\.dismiss) private var dismiss

    let iconOptions = [
        "cabinet.fill", "tshirt.fill", "shoe.fill", "bag.fill",
        "sun.max.fill", "snowflake", "briefcase.fill", "figure.run",
        "heart.fill", "star.fill", "sparkles", "leaf.fill"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Icon")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal.opacity(0.6))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color.terracotta : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Closet Name")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal.opacity(0.6))
                    TextField("e.g., Summer Outfits", text: $closetName)
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    closetService.createCloset(name: closetName, icon: selectedIcon)
                    dismiss()
                }) {
                    Text("Create Closet")
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(closetName.isEmpty ? Color.gray : Color.terracotta))
                }
                .disabled(closetName.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("New Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
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
                    .fill(Color.paperBeige)
                    .shadow(color: Color.warmShadow.opacity(0.06), radius: 4)
                    .frame(width: 100, height: 100)

                if let data = item.sketchData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .frame(width: 100, height: 100)
                        .blendMode(.multiply)
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
