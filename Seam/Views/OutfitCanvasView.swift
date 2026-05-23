import SwiftUI
import SwiftData

// MARK: - Canvas item runtime state

struct CanvasItemState: Identifiable {
    let item: ClothingItem
    var position: CGPoint
    var scale: CGFloat = 1.0
    var id: UUID { item.id }
}

// MARK: - Outfit Canvas

struct OutfitCanvasView: View {
    var existingOutfit: Outfit?
    var targetFolder: OutfitFolder?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]
    @Query(sort: \OutfitFolder.dateCreated) private var allFolders: [OutfitFolder]

    @State private var outfitName: String
    @State private var selectedFolder: OutfitFolder?
    @State private var canvasItems: [CanvasItemState] = []
    @State private var showItemPicker = false
    @State private var canvasSize: CGSize = .zero
    @State private var activeItemId: UUID? = nil
    @State private var didLoadPlacements = false
    @State private var showCreateFolder = false

    init(existingOutfit: Outfit? = nil, targetFolder: OutfitFolder? = nil) {
        self.existingOutfit = existingOutfit
        self.targetFolder = targetFolder
        _outfitName = State(initialValue: existingOutfit?.name ?? "")
        _selectedFolder = State(initialValue: existingOutfit?.folder ?? targetFolder)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            canvasArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(Color("SoftBackground").ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: canvasSize) { _, size in
            guard size != .zero, !didLoadPlacements else { return }
            didLoadPlacements = true
            if let outfit = existingOutfit { loadPlacements(from: outfit) }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.terracotta)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                TextField("Outfit name", text: $outfitName)
                    .font(.custom("PatrickHand-Regular", size: 18))
                    .foregroundColor(.antiqueTeal)
                    .multilineTextAlignment(.center)

                Spacer()

                Button(action: save) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.terracotta)
                }
            }

            folderPicker
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color("SoftBackground"))
        .sheet(isPresented: $showCreateFolder) {
            CreateOutfitFolderSheet { name, icon in
                let folder = OutfitFolder(name: name, icon: icon)
                modelContext.insert(folder)
                try? modelContext.save()
                selectedFolder = folder
            }
        }
    }

    private var folderPicker: some View {
        Menu {
            Button {
                selectedFolder = nil
            } label: {
                Label("No folder", systemImage: selectedFolder == nil ? "checkmark" : "")
            }
            if !allFolders.isEmpty {
                Divider()
                ForEach(allFolders) { folder in
                    Button {
                        selectedFolder = folder
                    } label: {
                        Label(folder.name, systemImage: selectedFolder?.id == folder.id ? "checkmark" : folder.icon)
                    }
                }
            }
            Divider()
            Button {
                showCreateFolder = true
            } label: {
                Label("New folder…", systemImage: "folder.badge.plus")
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: selectedFolder == nil ? "folder" : selectedFolder!.icon)
                    .font(.system(size: 12))
                Text(selectedFolder?.name ?? "No folder")
                    .font(.custom("PatrickHand-Regular", size: 13))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.antiqueTeal.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.antiqueTeal.opacity(0.08)))
        }
    }

    // MARK: Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            ZStack {
                PaperBackground()

                if canvasItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 44))
                            .foregroundColor(.antiqueTeal.opacity(0.25))
                        Text("Tap + to add items")
                            .font(.custom("PatrickHand-Regular", size: 18))
                            .foregroundColor(.antiqueTeal.opacity(0.35))
                    }
                }

                ForEach($canvasItems) { $state in
                    DraggableCanvasItem(
                        item: state.item,
                        position: $state.position,
                        scale: $state.scale,
                        isActive: activeItemId == state.id,
                        canvasSize: canvasSize
                    )
                    .onTapGesture { activeItemId = state.id }
                    .zIndex(activeItemId == state.id ? 1 : 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture { activeItemId = nil }
            .onAppear { canvasSize = geo.size }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.warmShadow.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack {
            Button(action: { showItemPicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add Items")
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.terracotta))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, 8)
        .background(Color("SoftBackground"))
        .sheet(isPresented: $showItemPicker) {
            ItemPickerSheet(
                allItems: allItems,
                selectedIds: Set(canvasItems.map(\.id)),
                onToggle: toggleItem
            )
        }
    }

    // MARK: - Logic

    private func toggleItem(_ item: ClothingItem) {
        if let index = canvasItems.firstIndex(where: { $0.id == item.id }) {
            canvasItems.remove(at: index)
            if activeItemId == item.id { activeItemId = nil }
        } else {
            let center = canvasSize == .zero
                ? CGPoint(x: 160, y: 280)
                : CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            canvasItems.append(CanvasItemState(item: item, position: center))
            activeItemId = item.id
        }
    }

    private func loadPlacements(from outfit: Outfit) {
        guard let data = outfit.placementsData else {
            canvasItems = gridFallback(for: outfit.items)
            return
        }
        // Try new format (payload with canvas size) first, then legacy array format
        let placements: [OutfitItemPlacement]
        if let payload = try? JSONDecoder().decode(OutfitPlacementsPayload.self, from: data) {
            placements = payload.placements
        } else if let legacy = try? JSONDecoder().decode([OutfitItemPlacement].self, from: data) {
            placements = legacy
        } else {
            canvasItems = gridFallback(for: outfit.items)
            return
        }
        let mapped = placements.compactMap { p -> CanvasItemState? in
            guard let item = outfit.items.first(where: { $0.id == p.itemId }) else { return nil }
            return CanvasItemState(item: item, position: CGPoint(x: p.x, y: p.y), scale: CGFloat(p.scale))
        }
        canvasItems = mapped.isEmpty ? gridFallback(for: outfit.items) : mapped
    }

    private func gridFallback(for items: [ClothingItem]) -> [CanvasItemState] {
        items.enumerated().map { idx, item in
            let col = CGFloat(idx % 3)
            let row = CGFloat(idx / 3)
            return CanvasItemState(item: item, position: CGPoint(x: 80 + col * 110, y: 100 + row * 130))
        }
    }

    private func save() {
        let placements = canvasItems.map {
            OutfitItemPlacement(itemId: $0.item.id, x: $0.position.x, y: $0.position.y, scale: Double($0.scale))
        }
        let payload = OutfitPlacementsPayload(
            canvasWidth: Double(canvasSize.width),
            canvasHeight: Double(canvasSize.height),
            placements: placements
        )
        let placementsData = try? JSONEncoder().encode(payload)

        if let outfit = existingOutfit {
            outfit.name = outfitName.isEmpty ? "Untitled Outfit" : outfitName
            outfit.items = canvasItems.map(\.item)
            outfit.folder = selectedFolder
            outfit.placementsData = placementsData
            outfit.thumbnailData = generateThumbnail(for: outfit)
        } else {
            let outfit = Outfit(
                name: outfitName.isEmpty ? "Untitled Outfit" : outfitName,
                items: canvasItems.map(\.item),
                folder: selectedFolder
            )
            outfit.placementsData = placementsData
            outfit.thumbnailData = generateThumbnail(for: outfit)
            modelContext.insert(outfit)
        }
        try? modelContext.save()
        dismiss()
    }

    private func generateThumbnail(for outfit: Outfit) -> Data? {
        outfit.renderThumbnail()?.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Outfit thumbnail renderer

extension Outfit {
    func renderThumbnail(targetSize: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let placementsData else { return nil }

        let baseItemSize: CGFloat = 100

        // Try new format (canvas size + placements)
        if let payload = try? JSONDecoder().decode(OutfitPlacementsPayload.self, from: placementsData),
           !payload.placements.isEmpty {
            return renderWithCanvasSize(
                payload.placements,
                canvasW: CGFloat(payload.canvasWidth),
                canvasH: CGFloat(payload.canvasHeight),
                baseItemSize: baseItemSize,
                targetSize: targetSize
            )
        }

        // Fallback: legacy format — use tight bounding box with padding
        guard let legacy = try? JSONDecoder().decode([OutfitItemPlacement].self, from: placementsData),
              !legacy.isEmpty else { return nil }
        return renderWithBoundingBox(legacy, baseItemSize: baseItemSize, targetSize: targetSize)
    }

    private func renderWithCanvasSize(
        _ placements: [OutfitItemPlacement],
        canvasW: CGFloat, canvasH: CGFloat,
        baseItemSize: CGFloat,
        targetSize: CGSize
    ) -> UIImage {
        // Bounding box of each item's visual extent (center ± half scaled size)
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for p in placements {
            let half = baseItemSize * CGFloat(p.scale) / 2
            minX = min(minX, CGFloat(p.x) - half)
            maxX = max(maxX, CGFloat(p.x) + half)
            minY = min(minY, CGFloat(p.y) - half)
            maxY = max(maxY, CGFloat(p.y) + half)
        }
        let contentW = maxX - minX
        let contentH = maxY - minY

        // Expand bounding box by 80% of content size (min 50pt) for breathing room,
        // then clamp to canvas bounds — asymmetric clamping preserves edge context
        // (e.g. item at bottom-right stays visually bottom-right in the thumbnail)
        let padX = max(50, contentW * 0.8)
        let padY = max(50, contentH * 0.8)
        let cropMinX = max(0, minX - padX)
        let cropMaxX = min(canvasW, maxX + padX)
        let cropMinY = max(0, minY - padY)
        let cropMaxY = min(canvasH, maxY + padY)
        let cropW = cropMaxX - cropMinX
        let cropH = cropMaxY - cropMinY

        let fitScale = min(targetSize.width / cropW, targetSize.height / cropH)
        let drawW = cropW * fitScale
        let drawH = cropH * fitScale
        let originX = (targetSize.width - drawW) / 2
        let originY = (targetSize.height - drawH) / 2

        return UIGraphicsImageRenderer(size: targetSize).image { ctx in
            PaperTexture.render(in: CGRect(origin: .zero, size: targetSize), context: ctx.cgContext)
            for p in placements {
                guard let item = items.first(where: { $0.id == p.itemId }),
                      let data = item.sketchData,
                      let img = UIImage(data: data) else { continue }
                let s = baseItemSize * CGFloat(p.scale) * fitScale
                let cx = (CGFloat(p.x) - cropMinX) * fitScale + originX
                let cy = (CGFloat(p.y) - cropMinY) * fitScale + originY
                img.draw(in: CGRect(x: cx - s / 2, y: cy - s / 2, width: s, height: s))
            }
        }
    }

    private func renderWithBoundingBox(
        _ placements: [OutfitItemPlacement],
        baseItemSize: CGFloat,
        targetSize: CGSize
    ) -> UIImage {
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for p in placements {
            let half = baseItemSize * CGFloat(p.scale) / 2
            minX = min(minX, CGFloat(p.x) - half)
            maxX = max(maxX, CGFloat(p.x) + half)
            minY = min(minY, CGFloat(p.y) - half)
            maxY = max(maxY, CGFloat(p.y) + half)
        }
        let contentW = maxX - minX
        let contentH = maxY - minY

        let padX = max(50, contentW * 0.8)
        let padY = max(50, contentH * 0.8)
        let cropMinX = minX - padX
        let cropMaxX = maxX + padX
        let cropMinY = minY - padY
        let cropMaxY = maxY + padY
        let cropW = cropMaxX - cropMinX
        let cropH = cropMaxY - cropMinY

        let fitScale = min(targetSize.width / cropW, targetSize.height / cropH)
        let drawW = cropW * fitScale
        let drawH = cropH * fitScale
        let offsetX = (targetSize.width - drawW) / 2
        let offsetY = (targetSize.height - drawH) / 2

        return UIGraphicsImageRenderer(size: targetSize).image { ctx in
            PaperTexture.render(in: CGRect(origin: .zero, size: targetSize), context: ctx.cgContext)
            for p in placements {
                guard let item = items.first(where: { $0.id == p.itemId }),
                      let data = item.sketchData,
                      let img = UIImage(data: data) else { continue }
                let s = baseItemSize * CGFloat(p.scale) * fitScale
                let cx = (CGFloat(p.x) - cropMinX) * fitScale + offsetX
                let cy = (CGFloat(p.y) - cropMinY) * fitScale + offsetY
                img.draw(in: CGRect(x: cx - s / 2, y: cy - s / 2, width: s, height: s))
            }
        }
    }
}

// MARK: - Draggable item on canvas

struct DraggableCanvasItem: View {
    let item: ClothingItem
    @Binding var position: CGPoint
    @Binding var scale: CGFloat
    let isActive: Bool
    let canvasSize: CGSize

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0

    private let baseSize: CGFloat = 100

    var body: some View {
        itemContent
            .frame(width: baseSize, height: baseSize)
            .scaleEffect(scale * pinchScale)
            .overlay(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [5])
                            )
                            .foregroundColor(.terracotta.opacity(0.7))
                    }
                }
            )
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 2)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let half = baseSize * scale / 2
                        position.x = max(half, min(canvasSize.width - half,
                            position.x + value.translation.width))
                        position.y = max(half, min(canvasSize.height - half,
                            position.y + value.translation.height))
                    }
                    .simultaneously(with:
                        MagnificationGesture()
                            .updating($pinchScale) { value, state, _ in state = value }
                            .onEnded { value in
                                scale = max(0.3, min(3.0, scale * value))
                            }
                    )
            )
    }

    @ViewBuilder
    private var itemContent: some View {
        if let data = item.sketchData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.warmCard)
                CategoryIcon(category: item.category, size: 32)
                    .foregroundColor(.terracotta.opacity(0.5))
            }
        }
    }
}

// MARK: - Item picker sheet

struct ItemPickerSheet: View {
    let allItems: [ClothingItem]
    let selectedIds: Set<UUID>
    let onToggle: (ClothingItem) -> Void

    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                if allItems.isEmpty {
                    Text("No items yet — sketch some first.")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(allItems) { item in
                                Button(action: { onToggle(item) }) {
                                    ZStack(alignment: .topTrailing) {
                                        ClothingItemCard(item: item)
                                        if selectedIds.contains(item.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.terracotta)
                                                .background(Circle().fill(Color.white).padding(3))
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.terracotta)
                }
            }
        }
    }
}
