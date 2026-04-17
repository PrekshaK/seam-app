import SwiftData
import SwiftUI

final class ClothingItemRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(_ item: ClothingItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func fetchAll() throws -> [ClothingItem] {
        let descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save() throws {
        try modelContext.save()
    }

    func delete(_ item: ClothingItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }
}
