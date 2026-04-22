import SwiftData
import SwiftUI

@Model
final class OutfitFolder {
    var id: UUID
    var name: String
    var icon: String
    var dateCreated: Date

    @Relationship(deleteRule: .nullify, inverse: \Outfit.folder)
    var outfits: [Outfit]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder.fill",
        dateCreated: Date = Date(),
        outfits: [Outfit] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.dateCreated = dateCreated
        self.outfits = outfits
    }
}
