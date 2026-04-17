import SwiftUI
import SwiftData

@main
struct SeamApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClothingItem.self,
            Closet.self,
            Outfit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If this fires, the on-disk schema is incompatible with the current model.
            // Add a SchemaMigrationPlan before shipping — never silently delete user data.
            fatalError("ModelContainer failed — schema mismatch or corruption. Error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
