import SwiftData
import SwiftUI

final class OutfitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ outfit: Outfit) throws {
        modelContext.insert(outfit)
        try modelContext.save()
    }

    func fetchAll() throws -> [Outfit] {
        let descriptor = FetchDescriptor<Outfit>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save() throws {
        try modelContext.save()
    }

    func delete(_ outfit: Outfit) throws {
        modelContext.delete(outfit)
        try modelContext.save()
    }
}
