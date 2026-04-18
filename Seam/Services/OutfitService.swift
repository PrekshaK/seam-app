import SwiftData
import SwiftUI

@Observable
final class OutfitService {
    private let repo: OutfitRepository

    init(modelContext: ModelContext) {
        self.repo = OutfitRepository(modelContext: modelContext)
    }

    func createOutfit(name: String, closet: Closet, items: [ClothingItem]) {
        let outfit = Outfit(name: name, closet: closet, items: items)
        closet.outfits.append(outfit)
        try? repo.create(outfit)
    }

    func addItem(_ item: ClothingItem, to outfit: Outfit) {
        guard !outfit.items.contains(where: { $0.id == item.id }) else { return }
        outfit.items.append(item)
        try? repo.save()
    }

    func removeItem(_ item: ClothingItem, from outfit: Outfit) {
        outfit.items.removeAll { $0.id == item.id }
        try? repo.save()
    }

    func deleteOutfit(_ outfit: Outfit) {
        try? repo.delete(outfit)
    }

    func updateName(_ outfit: Outfit, name: String) {
        outfit.name = name
        try? repo.save()
    }
}
