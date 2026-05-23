import Foundation

struct OutfitItemPlacement: Codable {
    var itemId: UUID
    var x: Double
    var y: Double
    var scale: Double
}

// Wrapper that carries canvas dimensions alongside placements so the thumbnail
// renderer can faithfully reproduce item positions relative to the canvas.
struct OutfitPlacementsPayload: Codable {
    var canvasWidth: Double
    var canvasHeight: Double
    var placements: [OutfitItemPlacement]
}
