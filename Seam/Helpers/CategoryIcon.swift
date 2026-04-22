import SwiftUI

struct CategoryIcon: View {
    let category: ClothingCategory
    var size: CGFloat = 22

    var body: some View {
        if let symbol = category.sfSymbol {
            Image(systemName: symbol)
                .font(.system(size: size))
        } else if let asset = category.customAsset {
            Image(asset)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: size * 1.3, height: size * 1.3)
        }
    }
}
