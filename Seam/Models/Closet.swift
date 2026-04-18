import SwiftData
import SwiftUI

@Model
final class Closet {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var dateCreated: Date

    @Relationship(deleteRule: .cascade)
    var outfits: [Outfit]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "cabinet.fill",
        color: String = "teal",
        dateCreated: Date = Date(),
        outfits: [Outfit] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.dateCreated = dateCreated
        self.outfits = outfits
    }
}
