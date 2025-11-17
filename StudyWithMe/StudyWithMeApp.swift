import SwiftUI

@main
struct StudyWithMeApp: App {
    
    // Assicurati che questi siano qui
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var settingsStore = SettingsStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // E assicurati che vengano iniettati qui
                .environmentObject(goalsStore)
                .environmentObject(sessionStore)
                .environmentObject(settingsStore)
        }
    }
}
