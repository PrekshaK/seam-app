import SwiftUI
import SwiftData

@main
struct SeamApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClothingItem.self,
            Closet.self,
            Outfit.self,
            OutfitFolder.self,
        ])
        // Lightweight migration: SwiftData automatically handles adding new
        // optional fields and new models without touching existing data.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Only fires on a destructive schema change (e.g. renaming a field,
            // changing a required type). Add a SchemaMigrationPlan before doing that.
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
