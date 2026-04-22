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
                OutfitsView()
                    .opacity(selectedTab == 2 ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                tabButton(icon: "tshirt.fill", label: "Items", tag: 0)
                sketchButton
                tabButton(icon: "hanger", label: "Outfits", tag: 2)
            }
            .frame(height: 56)
            .background(Color("SoftBackground"))
            .shadow(color: Color.warmShadow.opacity(0.08), radius: 8, x: 0, y: -2)
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
            .foregroundColor(selectedTab == tag ? .antiqueTeal : .antiqueTeal.opacity(0.35))
            .frame(maxWidth: .infinity)
        }
    }

    private var sketchButton: some View {
        Button(action: { selectedTab = 1 }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.terracotta)
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.terracotta.opacity(0.35), radius: 6, x: 0, y: 3)
                    Image(systemName: "pencil")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("Sketch")
                    .font(.custom("PatrickHand-Regular", size: 13))
                    .foregroundColor(selectedTab == 1 ? .terracotta : .antiqueTeal.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SketchButtonStyle())
    }
}

struct SketchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
