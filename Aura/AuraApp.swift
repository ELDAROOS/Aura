import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Artist.self,
            Album.self,
            Track.self,
            Playlist.self,
            UserActivity.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
        MenuBarExtra("Aura", systemImage: "star.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
