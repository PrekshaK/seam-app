import SwiftData
import SwiftUI

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var sketchData: Data?
    var drawingData: Data?
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
        drawingData: Data? = nil,
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
        self.drawingData = drawingData
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

    // SF Symbol name — nil means use a custom asset instead
    var sfSymbol: String? {
        switch self {
        case .top: return "tshirt.fill"
        case .bottom: return nil
        case .dress: return nil
        case .outerwear: return "jacket.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return nil
        case .other: return "tag.fill"
        }
    }

    // Custom asset name — only set for noun project icons
    var customAsset: String? {
        switch self {
        case .bottom: return "noun-skirt"
        case .dress: return "noun-dress"
        case .accessories: return "noun-necklace"
        default: return nil
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
