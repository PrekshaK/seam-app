import SwiftUI
import SwiftData

struct NewHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var allItems: [ClothingItem]
    @Query(sort: \Closet.dateCreated) private var closets: [Closet]

    @State private var showDrawView = false
    @State private var showCreateCloset = false
    @State private var selectedItem: ClothingItem?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var closetService: ClosetService {
        ClosetService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Closets section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("My Closets")
                                    .font(.custom("PatrickHand-Regular", size: 26))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: { showCreateCloset = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.teal)
                                }
                            }
                            .padding(.horizontal, 20)

                            if closets.isEmpty {
                                Button(action: { showCreateCloset = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 28))
                                            .foregroundColor(.teal)
                                        Text("Create your first closet")
                                            .font(.custom("PatrickHand-Regular", size: 20))
                                            .foregroundColor(.teal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                            .foregroundColor(.teal.opacity(0.5))
                                    )
                                }
                                .padding(.horizontal, 20)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(closets) { closet in
                                            NavigationLink(destination: ClosetDetailView(closet: closet)) {
                                                ClosetCard(closet: closet)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        // Add closet card
                                        Button(action: { showCreateCloset = true }) {
                                            VStack(spacing: 10) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                        .foregroundColor(.teal.opacity(0.5))
                                                        .frame(width: 100, height: 100)
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 28))
                                                        .foregroundColor(.teal.opacity(0.6))
                                                }
                                                Text("New")
                                                    .font(.custom("PatrickHand-Regular", size: 15))
                                                    .foregroundColor(.teal.opacity(0.7))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        Divider().padding(.horizontal, 20)

                        // MARK: All Items section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("All Items")
                                .font(.custom("PatrickHand-Regular", size: 26))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)

                            if allItems.isEmpty {
                                Button(action: { showDrawView = true }) {
                                    VStack(spacing: 14) {
                                        Image(systemName: "pencil.tip.crop.circle")
                                            .font(.system(size: 52))
                                            .foregroundColor(.teal.opacity(0.5))
                                        Text("Sketch your first piece ✏️")
                                            .font(.custom("PatrickHand-Regular", size: 22))
                                            .foregroundColor(.teal)
                                        Text("Tap to open the drawing canvas")
                                            .font(.custom("PatrickHand-Regular", size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7]))
                                            .foregroundColor(.teal.opacity(0.3))
                                    )
                                }
                                .padding(.horizontal, 20)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            } else {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(allItems) { item in
                                        ClothingItemCard(item: item)
                                            .onTapGesture { selectedItem = item }
                                            .contextMenu {
                                                Button {
                                                    closetService.toggleFavorite(item)
                                                } label: {
                                                    Label(
                                                        item.isFavorite ? "Unfavorite" : "Favorite",
                                                        systemImage: item.isFavorite ? "heart.slash" : "heart"
                                                    )
                                                }
                                                Button(role: .destructive) {
                                                    closetService.deleteItem(item)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("My Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDrawView = true }) {
                        Image(systemName: "pencil.tip.crop.circle.badge.plus")
                            .font(.system(size: 22))
                            .foregroundColor(.teal)
                    }
                }
            }
            .fullScreenCover(isPresented: $showDrawView) {
                DrawView()
            }
            .sheet(isPresented: $showCreateCloset) {
                CreateClosetSheet(closetService: closetService)
            }
            .sheet(item: $selectedItem) { item in
                EditItemSheet(item: item)
            }
        }
    }
}

// MARK: - Closet Card

struct ClosetCard: View {
    let closet: Closet

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: closet.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.teal)
            }
            Text(closet.name)
                .font(.custom("PatrickHand-Regular", size: 15))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text("\(closet.outfits.count) outfit\(closet.outfits.count == 1 ? "" : "s")")
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
    }
}

// MARK: - Clothing Item Card

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 4)
                    .frame(width: 100, height: 100)

                if let data = item.sketchData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.teal.opacity(0.5))
                }

                if item.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.pink)
                                .padding(5)
                        }
                        Spacer()
                    }
                }
            }

            Text(item.name.isEmpty ? item.category.rawValue : item.name)
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Create Closet Sheet

struct CreateClosetSheet: View {
    let closetService: ClosetService

    @State private var closetName = ""
    @State private var selectedIcon = "cabinet.fill"
    @Environment(\.dismiss) private var dismiss

    let iconOptions = [
        "cabinet.fill", "tshirt.fill", "shoe.fill", "bag.fill",
        "sun.max.fill", "snowflake", "briefcase.fill", "figure.run",
        "heart.fill", "star.fill", "sparkles", "leaf.fill"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Icon")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color.teal : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Closet Name")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.secondary)

                    TextField("e.g., Summer Outfits", text: $closetName)
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    closetService.createCloset(name: closetName, icon: selectedIcon)
                    dismiss()
                }) {
                    Text("Create Closet")
                        .font(.custom("PatrickHand-Regular", size: 22))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(closetName.isEmpty ? Color.gray : Color.teal)
                        )
                }
                .disabled(closetName.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
            .background(Color("SoftBackground").ignoresSafeArea())
            .navigationTitle("New Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("PatrickHand-Regular", size: 18))
                }
            }
        }
    }
}

#Preview {
    NewHomeView()
        .modelContainer(for: [ClothingItem.self, Closet.self, Outfit.self], inMemory: true)
}
