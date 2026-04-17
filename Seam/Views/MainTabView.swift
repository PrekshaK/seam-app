import SwiftUI

struct MainTabView: View {
    static let background = UIColor(named: "SoftBackground") ?? UIColor.systemBackground

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = MainTabView.background
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NewHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            DrawView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "pencil.tip")
                    Text("Draw")
                }
                .tag(1)

            OutfitsView()
                .tabItem {
                    Image(systemName: "hanger")
                    Text("Outfits")
                }
                .tag(2)
        }
        .tint(.teal)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
