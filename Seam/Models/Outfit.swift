import SwiftData
import SwiftUI

@Model
final class Outfit {
    var id: UUID
    var name: String
    var dateCreated: Date
    var notes: String?

    @Relationship(deleteRule: .nullify, inverse: \Closet.outfits)
    var closet: Closet?

    @Relationship(deleteRule: .nullify, inverse: \ClothingItem.outfits)
    var items: [ClothingItem]

    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        notes: String? = nil,
        closet: Closet? = nil,
        items: [ClothingItem] = []
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.notes = notes
        self.closet = closet
        self.items = items
    }
}
