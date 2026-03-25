import SwiftUI
import SwiftData

@main
struct HockeyStatsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Team.self,
            Player.self,
            Game.self,
            GameEvent.self
        ])
    }
}
