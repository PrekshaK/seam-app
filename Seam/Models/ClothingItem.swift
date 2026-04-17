import SwiftData
import SwiftUI

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var sketchData: Data?
    var color: String?
    var season: Season?
    var isFavorite: Bool
    var dateAdded: Date
    var lastWorn: Date?
    var notes: String?

    @Relationship(deleteRule: .nullify)
    var outfits: [Outfit]

    init(
        id: UUID = UUID(),
        name: String = "",
        category: ClothingCategory = .top,
        sketchData: Data? = nil,
        color: String? = nil,
        season: Season? = nil,
        isFavorite: Bool = false,
        dateAdded: Date = Date(),
        lastWorn: Date? = nil,
        notes: String? = nil,
        outfits: [Outfit] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.sketchData = sketchData
        self.color = color
        self.season = season
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.lastWorn = lastWorn
        self.notes = notes
        self.outfits = outfits
    }
}

// MARK: - Supporting Enums

enum ClothingCategory: String, Codable, CaseIterable {
    case top = "Top"
    case bottom = "Bottom"
    case dress = "Dress"
    case outerwear = "Outerwear"
    case shoes = "Shoes"
    case accessories = "Accessories"
    case other = "Other"

    var icon: String {
        switch self {
        case .top: return "tshirt.fill"
        case .bottom: return "rectangle.fill"
        case .dress: return "figure.dress.line.vertical.figure"
        case .outerwear: return "jacket.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "bag.fill"
        case .other: return "tag.fill"
        }
    }
}

enum Season: String, Codable, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case allYear = "All Year"

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "wind"
        case .winter: return "snowflake"
        case .allYear: return "calendar"
        }
    }
}
