import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Scheda 1
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            // Scheda 2
            GoalsView()
                .tabItem {
                    Label("Obiettivi", systemImage: "checkmark.circle")
                }
            
            // Scheda 3
            HistoryView()
                .tabItem {
                    Label("Cronologia", systemImage: "book.fill")
                }
            
            // Scheda 4
            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape.fill")
                }
        }
        // --- MODIFICA QUI ---
        // Ho cambiato il colore delle icone
        // in basso da arancione a blu.
        .tint(.blue)
    }
}
