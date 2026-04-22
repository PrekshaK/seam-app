import SwiftUI
import SwiftData

struct ClosetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Closet.dateCreated) private var closets: [Closet]
    @State private var showCreateCloset = false
    @State private var selectedCloset: Closet?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var closetService: ClosetService { ClosetService(modelContext: modelContext) }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ZStack {
                Color("SoftBackground").ignoresSafeArea()

                if closets.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedCloset) {
                        ForEach(closets) { closet in
                            ClosetSidebarRow(closet: closet, isSelected: selectedCloset == closet)
                                .tag(closet)
                                .listRowBackground(selectedCloset == closet ? Color.antiqueTeal.opacity(0.08) : Color("SoftBackground"))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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
            .onChange(of: closets) { _, newClosets in
                if let sel = selectedCloset, !newClosets.contains(sel) {
                    selectedCloset = nil
                }
            }
        } detail: {
            if let closet = selectedCloset {
                ClosetDetailView(closet: closet)
            } else {
                ZStack {
                    Color("SoftBackground").ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "cabinet")
                            .font(.system(size: 52))
                            .foregroundColor(.antiqueTeal.opacity(0.2))
                        Text("Select a closet")
                            .font(.custom("PatrickHand-Regular", size: 22))
                            .foregroundColor(.antiqueTeal.opacity(0.4))
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var emptyState: some View {
        Button(action: { showCreateCloset = true }) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.antiqueTeal.opacity(0.6))
                Text("Create your first closet")
                    .font(.custom("PatrickHand-Regular", size: 22))
                    .foregroundColor(.antiqueTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.antiqueTeal.opacity(0.4))
            )
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Sidebar Row

struct ClosetSidebarRow: View {
    let closet: Closet
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.antiqueTeal : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.antiqueTeal)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.antiqueTeal.opacity(0.3), radius: 4, x: 0, y: 2)
                    Image(systemName: closet.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(closet.name)
                        .font(.custom("PatrickHand-Regular", size: 20))
                        .foregroundColor(.antiqueTeal)
                    Text("\(closet.outfits.count) outfit\(closet.outfits.count == 1 ? "" : "s")")
                        .font(.custom("PatrickHand-Regular", size: 14))
                        .foregroundColor(.antiqueTeal.opacity(0.55))
                }

                Spacer()
            }
            .padding(.leading, 13)
            .padding(.vertical, 6)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Closet Card (kept for any other uses)

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
