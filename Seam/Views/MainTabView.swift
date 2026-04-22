import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var sketchEditingItem: ClothingItem? = nil

    init() {
        let teal = UIColor(red: 0.176, green: 0.357, blue: 0.341, alpha: 1.0)
        let bg = UIColor(named: "SoftBackground") ?? UIColor.systemBackground

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
        VStack(spacing: 0) {
            ZStack {
                ItemsView(
                    onSketchNew: { sketchEditingItem = nil; selectedTab = 1 },
                    onSketchEdit: { item in sketchEditingItem = item; selectedTab = 1 }
                )
                .opacity(selectedTab == 0 ? 1 : 0)
                DrawView(
                    editingItem: sketchEditingItem,
                    isActive: selectedTab == 1,
                    onClose: { sketchEditingItem = nil; selectedTab = 0 }
                )
                .opacity(selectedTab == 1 ? 1 : 0)
                ClosetsView()
                    .opacity(selectedTab == 2 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(Color.antiqueTeal.opacity(0.12))
                .frame(height: 1)

            HStack(spacing: 0) {
                tabButton(icon: "tshirt.fill", label: "Items", tag: 0)
                sketchButton
                tabButton(icon: "cabinet.fill", label: "Closets", tag: 2)
            }
            .frame(height: 56)
            .background(Color("SoftBackground"))
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        Button(action: { selectedTab = tag }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.custom("PatrickHand-Regular", size: 13))
            }
            .foregroundColor(selectedTab == tag ? .terracotta : .antiqueTeal.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
    }

    private var sketchButton: some View {
        Button(action: { selectedTab = 1 }) {
            VStack(spacing: 4) {
                Image(systemName: "pencil")
                    .font(.system(size: 22))
                Text("Sketch")
                    .font(.custom("PatrickHand-Regular", size: 13))
            }
            .foregroundColor(selectedTab == 1 ? .terracotta : .antiqueTeal.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
