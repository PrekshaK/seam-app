import SwiftUI
import SwiftData

struct ClosetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Closet.dateCreated) private var closets: [Closet]
    @State private var showCreateCloset = false

    private var closetService: ClosetService { ClosetService(modelContext: modelContext) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                if closets.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(closets) { closet in
                                NavigationLink(destination: ClosetDetailView(closet: closet)) {
                                    ClosetCard(closet: closet)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Closets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateCloset = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.terracotta)
                    }
                }
            }
            .sheet(isPresented: $showCreateCloset) {
                CreateClosetSheet(closetService: closetService)
            }
        }
    }

    private var emptyState: some View {
        Button(action: { showCreateCloset = true }) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.terracotta.opacity(0.6))
                Text("Create your first closet")
                    .font(.custom("PatrickHand-Regular", size: 22))
                    .foregroundColor(.terracotta)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.terracotta.opacity(0.4))
            )
            .padding(.horizontal, 32)
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
                    .fill(Color.antiqueTeal)
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: Color.antiqueTeal.opacity(0.4), radius: 6, x: 0, y: 3)
                Image(systemName: closet.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.85))
            }
            Text(closet.name)
                .font(.custom("PatrickHand-Regular", size: 16))
                .foregroundColor(.antiqueTeal)
                .lineLimit(1)
            Text("\(closet.outfits.count) outfit\(closet.outfits.count == 1 ? "" : "s")")
                .font(.custom("PatrickHand-Regular", size: 13))
                .foregroundColor(.antiqueTeal.opacity(0.6))
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
                        .foregroundColor(.antiqueTeal.opacity(0.6))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color.terracotta : Color.gray.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Closet Name")
                        .font(.custom("PatrickHand-Regular", size: 18))
                        .foregroundColor(.antiqueTeal.opacity(0.6))
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
                        .background(RoundedRectangle(cornerRadius: 16).fill(closetName.isEmpty ? Color.gray : Color.terracotta))
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
