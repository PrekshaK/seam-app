import SwiftUI

struct MainTabView: View {
    init() {
        let teal = UIColor(red: 0.176, green: 0.357, blue: 0.341, alpha: 1.0)
        let bg = UIColor(named: "SoftBackground") ?? UIColor.systemBackground

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = bg
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = bg
        navAppearance.titleTextAttributes = [
            .foregroundColor: teal,
            .font: UIFont(name: "PatrickHand-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: teal,
            .font: UIFont(name: "PatrickHand-Regular", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = teal
    }

    var body: some View {
        TabView {
            ItemsView()
                .tabItem {
                    Image(systemName: "tshirt.fill")
                    Text("Items")
                }

            ClosetsView()
                .tabItem {
                    Image(systemName: "cabinet.fill")
                    Text("Closets")
                }
        }
        .tint(.terracotta)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
