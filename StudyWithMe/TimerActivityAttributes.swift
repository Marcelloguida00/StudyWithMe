import Foundation
import ActivityKit

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dati che si aggiornano (dinamici)
        var endTime: Date       // Il momento in cui il timer scade
        var progress: Double    // L'avanzamento da 0.0 a 1.0
    }
    
    // Dati che non cambiano (statici)
    var timerName: String   // Es. "Pomodoro", "Pausa Corta"
}
