import SwiftData
import SwiftUI

@Observable
final class ClosetService {
    private let closetRepo: ClosetRepository
    private let itemRepo: ClothingItemRepository

    init(modelContext: ModelContext) {
        self.closetRepo = ClosetRepository(modelContext: modelContext)
        self.itemRepo = ClothingItemRepository(modelContext: modelContext)
    }

    // MARK: - Closets

    func createCloset(name: String, icon: String = "cabinet.fill", color: String = "teal") {
        let closet = Closet(name: name, icon: icon, color: color)
        try? closetRepo.create(closet)
    }

    func deleteCloset(_ closet: Closet) {
        try? closetRepo.delete(closet)
    }

    // MARK: - Clothing Items

    func addItem(name: String, category: ClothingCategory, sketchImage: UIImage?) {
        let item = ClothingItem(
            name: name.isEmpty ? "Untitled" : name,
            category: category,
            sketchData: sketchImage?.pngData()
        )
        try? itemRepo.add(item)
    }

    func updateItem(_ item: ClothingItem, name: String, category: ClothingCategory, notes: String?) {
        item.name = name
        item.category = category
        item.notes = notes
        try? itemRepo.save()
    }

    func deleteItem(_ item: ClothingItem) {
        try? itemRepo.delete(item)
    }

    func toggleFavorite(_ item: ClothingItem) {
        item.isFavorite.toggle()
        try? itemRepo.save()
    }
}
