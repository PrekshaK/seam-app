import SwiftUI
import SwiftData

enum OutfitFolderSelection: Hashable {
    case allOutfits
    case folder(OutfitFolder)
}

struct OutfitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Outfit.dateCreated, order: .reverse) private var allOutfits: [Outfit]
    @Query(sort: \OutfitFolder.dateCreated) private var folders: [OutfitFolder]

    @State private var sidebarSelection: OutfitFolderSelection? = .allOutfits
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showNewOutfit = false
    @State private var editingOutfit: Outfit? = nil
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var newFolderIcon = "folder.fill"

    private var targetFolder: OutfitFolder? {
        if case .folder(let f) = sidebarSelection { return f }
        return nil
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .fullScreenCover(isPresented: $showNewOutfit) {
            OutfitCanvasView(targetFolder: targetFolder)
        }
        .fullScreenCover(item: $editingOutfit) { outfit in
            OutfitCanvasView(existingOutfit: outfit)
        }
        .sheet(isPresented: $showCreateFolder) {
            CreateOutfitFolderSheet(onSave: { name, icon in
                let folder = OutfitFolder(name: name, icon: icon)
                modelContext.insert(folder)
                try? modelContext.save()
                sidebarSelection = .folder(folder)
            })
        }
        .onChange(of: folders) { _, newFolders in
            if case .folder(let f) = sidebarSelection, !newFolders.contains(f) {
                sidebarSelection = .allOutfits
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()
            List(selection: $sidebarSelection) {
                AllOutfitsSidebarRow(count: allOutfits.count, isSelected: sidebarSelection == .allOutfits)
                    .tag(OutfitFolderSelection.allOutfits)
                    .listRowBackground(sidebarSelection == .allOutfits ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))

                ForEach(folders) { folder in
                    OutfitFolderSidebarRow(folder: folder, isSelected: sidebarSelection == .folder(folder))
                        .tag(OutfitFolderSelection.folder(folder))
                        .listRowBackground(sidebarSelection == .folder(folder) ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if sidebarSelection == .folder(folder) { sidebarSelection = .allOutfits }
                                modelContext.delete(folder)
                                try? modelContext.save()
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
        .navigationTitle("Outfits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showCreateFolder = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.antiqueTeal)
                }
                Button(action: { showNewOutfit = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.terracotta)
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if case .folder(let folder) = sidebarSelection {
            OutfitFolderDetailView(
                folder: folder,
                onNewOutfit: { showNewOutfit = true },
                onEdit: { editingOutfit = $0 }
            )
        } else {
            OutfitGridView(
                outfits: allOutfits,
                title: "All Outfits",
                onNewOutfit: { showNewOutfit = true },
                onEdit: { editingOutfit = $0 }
            )
        }
    }
}

// MARK: - Outfit Grid (reusable for both All Outfits and folder detail)

struct OutfitGridView: View {
    let outfits: [Outfit]
    let title: String
    let onNewOutfit: () -> Void
    let onEdit: (Outfit) -> Void

    @Environment(\.modelContext) private var modelContext
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color("SoftBackground").ignoresSafeArea()

            if outfits.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 28) {
                        ForEach(outfits) { outfit in
                            Button(action: { onEdit(outfit) }) {
                                OutfitPolaroidCard(outfit: outfit)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(outfit)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete Outfit", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onNewOutfit) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundColor(.terracotta)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hanger")
                .font(.system(size: 56))
                .foregroundColor(.antiqueTeal.opacity(0.3))
            Text("No outfits here")
                .font(.custom("PatrickHand-Regular", size: 26))
                .foregroundColor(.antiqueTeal)
            Button(action: onNewOutfit) {
                Label("Build an Outfit", systemImage: "plus.circle.fill")
                    .font(.custom("PatrickHand-Regular", size: 20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.terracotta))
            }
        }
    }
}

// MARK: - Folder Detail

struct OutfitFolderDetailView: View {
    let folder: OutfitFolder
    let onNewOutfit: () -> Void
    let onEdit: (Outfit) -> Void

    private var sortedOutfits: [Outfit] {
        folder.outfits.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        OutfitGridView(
            outfits: sortedOutfits,
            title: folder.name,
            onNewOutfit: onNewOutfit,
            onEdit: onEdit
        )
    }
}

// MARK: - All Outfits Sidebar Row

struct AllOutfitsSidebarRow: View {
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
                    Text("All Outfits")
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.antiqueTeal)
                    Text("\(count) outfit\(count == 1 ? "" : "s")")
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

// MARK: - Folder Sidebar Row

struct OutfitFolderSidebarRow: View {
    let folder: OutfitFolder
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
                    Image(systemName: folder.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(folder.name)
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.antiqueTeal)
                    Text("\(folder.outfits.count) outfit\(folder.outfits.count == 1 ? "" : "s")")
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

// MARK: - Create Outfit Folder Sheet

struct CreateOutfitFolderSheet: View {
    let onSave: (String, String) -> Void

    @State private var folderName = ""
    @State private var selectedIcon = "folder.fill"
    @Environment(\.dismiss) private var dismiss

    let iconOptions = [
        "folder.fill", "star.fill", "heart.fill", "sun.max.fill",
        "moon.fill", "sparkles", "leaf.fill", "snowflake",
        "bag.fill", "airplane", "figure.run", "music.note"
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
                    Text("Folder Name")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal.opacity(0.6))
                    TextField("e.g., Summer Looks", text: $folderName)
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    onSave(folderName, selectedIcon)
                    dismiss()
                }) {
                    Text("Create Folder")
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(folderName.isEmpty ? Color.gray : Color.terracotta))
                }
                .disabled(folderName.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("New Folder")
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

// MARK: - Polaroid Card

struct OutfitPolaroidCard: View {
    let outfit: Outfit
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 0) {
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
