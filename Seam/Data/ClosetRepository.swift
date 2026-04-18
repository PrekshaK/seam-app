import SwiftData
import SwiftUI

final class ClosetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ closet: Closet) throws {
        modelContext.insert(closet)
        try modelContext.save()
    }

    func fetchAll() throws -> [Closet] {
        let descriptor = FetchDescriptor<Closet>(
            sortBy: [SortDescriptor(\.dateCreated, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func delete(_ closet: Closet) throws {
        modelContext.delete(closet)
        try modelContext.save()
    }
}
