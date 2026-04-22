import SwiftData
import SwiftUI

@Model
final class Outfit {
    var id: UUID
    var name: String
    var dateCreated: Date
    var notes: String?
    var placementsData: Data?
    var thumbnailData: Data?

    @Relationship(deleteRule: .nullify, inverse: \ClothingItem.outfits)
    var items: [ClothingItem]

    @Relationship(deleteRule: .nullify)
    var folder: OutfitFolder?

    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        notes: String? = nil,
        items: [ClothingItem] = [],
        folder: OutfitFolder? = nil
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.notes = notes
        self.items = items
        self.folder = folder
    }
}
