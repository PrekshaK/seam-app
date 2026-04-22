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
    let closet: Closet
    var existingOutfit: Outfit?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]

    @State private var outfitName: String
    @State private var canvasItems: [CanvasItemState] = []
    @State private var showItemPicker = false
    @State private var canvasSize: CGSize = .zero
    @State private var activeItemId: UUID? = nil
    @State private var didLoadPlacements = false

    init(closet: Closet, existingOutfit: Outfit? = nil) {
        self.closet = closet
        self.existingOutfit = existingOutfit
        _outfitName = State(initialValue: existingOutfit?.name ?? "")
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
        .onChange(of: canvasSize) { size in
            guard size != .zero, !didLoadPlacements else { return }
            didLoadPlacements = true
            if let outfit = existingOutfit { loadPlacements(from: outfit) }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.antiqueTeal)
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
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color("SoftBackground"))
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
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.antiqueTeal))
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
        if let data = outfit.placementsData,
           let placements = try? JSONDecoder().decode([OutfitItemPlacement].self, from: data) {
            canvasItems = placements.compactMap { p in
                guard let item = outfit.items.first(where: { $0.id == p.itemId }) else { return nil }
                return CanvasItemState(item: item, position: CGPoint(x: p.x, y: p.y), scale: CGFloat(p.scale))
            }
        } else {
            // No saved positions — spread items in a grid
            canvasItems = outfit.items.enumerated().map { idx, item in
                let col = CGFloat(idx % 3)
                let row = CGFloat(idx / 3)
                return CanvasItemState(
                    item: item,
                    position: CGPoint(x: 80 + col * 110, y: 100 + row * 130)
                )
            }
        }
    }

    private func save() {
        let placements = canvasItems.map {
            OutfitItemPlacement(itemId: $0.item.id, x: $0.position.x, y: $0.position.y, scale: Double($0.scale))
        }
        let placementsData = try? JSONEncoder().encode(placements)

        if let outfit = existingOutfit {
            outfit.name = outfitName.isEmpty ? "Untitled Outfit" : outfitName
            outfit.items = canvasItems.map(\.item)
            outfit.placementsData = placementsData
            outfit.thumbnailData = generateThumbnail(for: outfit)
        } else {
            let outfit = Outfit(
                name: outfitName.isEmpty ? "Untitled Outfit" : outfitName,
                closet: closet,
                items: canvasItems.map(\.item)
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
    func renderThumbnail(targetSize: CGSize = CGSize(width: 200, height: 280)) -> UIImage? {
        guard let placementsData,
              let placements = try? JSONDecoder().decode([OutfitItemPlacement].self, from: placementsData),
              !placements.isEmpty else { return nil }

        let baseItemSize: CGFloat = 100

        // Find bounding box of all placed items
        let xs = placements.map { CGFloat($0.x) }
        let ys = placements.map { CGFloat($0.y) }
        let minX = xs.min()! - baseItemSize / 2
        let maxX = xs.max()! + baseItemSize / 2
        let minY = ys.min()! - baseItemSize / 2
        let maxY = ys.max()! + baseItemSize / 2
        let contentW = max(maxX - minX, 1)
        let contentH = max(maxY - minY, 1)

        let scale = min(targetSize.width / contentW, targetSize.height / contentH)
        let offsetX = (targetSize.width  - contentW * scale) / 2
        let offsetY = (targetSize.height - contentH * scale) / 2

        return UIGraphicsImageRenderer(size: targetSize).image { ctx in
            PaperTexture.render(in: CGRect(origin: .zero, size: targetSize), context: ctx.cgContext)
            for p in placements {
                guard let item = items.first(where: { $0.id == p.itemId }),
                      let data = item.sketchData,
                      let img = UIImage(data: data) else { continue }
                let s = baseItemSize * CGFloat(p.scale) * scale
                let x = (CGFloat(p.x) - minX) * scale + offsetX - s / 2
                let y = (CGFloat(p.y) - minY) * scale + offsetY - s / 2
                img.draw(in: CGRect(x: x, y: y, width: s, height: s))
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
                        .foregroundColor(.antiqueTeal)
                }
            }
        }
    }
}
