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

    @AppStorage("app_language") private var appLanguage: String = "system"
    @AppStorage("app_theme") private var appTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, appLanguage == "system" ? .current : Locale(identifier: appLanguage))
                .preferredColorScheme(appTheme == "system" ? nil : (appTheme == "dark" ? .dark : .light))
        }
        .modelContainer(sharedModelContainer)
        
        MenuBarExtra("Aura", systemImage: "star.fill") {
            MenuBarView()
                .environment(\.locale, appLanguage == "system" ? .current : Locale(identifier: appLanguage))
                .preferredColorScheme(appTheme == "system" ? nil : (appTheme == "dark" ? .dark : .light))
        }
        .menuBarExtraStyle(.window)
    }
}
