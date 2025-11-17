import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Durata Timer (minuti)")) {
                    
                    Stepper("Pomodoro: \(settingsStore.pomodoroMinutes) min",
                            value: $settingsStore.pomodoroMinutes,
                            in: 5...60,
                            step: 1)
                    
                    Stepper("Pausa Corta: \(settingsStore.shortBreakMinutes) min",
                            value: $settingsStore.shortBreakMinutes,
                            in: 1...15,
                            step: 1)
                    
                    Stepper("Pausa Lunga: \(settingsStore.longBreakMinutes) min",
                            value: $settingsStore.longBreakMinutes,
                            in: 10...30,
                            step: 1)
                    
                    // NUOVO STEPPER
                    Stepper("Pomodori per Pausa Lunga: \(settingsStore.pomodorosBeforeLongBreak)",
                            value: $settingsStore.pomodorosBeforeLongBreak,
                            in: 2...8,
                            step: 1)
                }
                
                // --- SEZIONE Modalità Studio ---
                Section(header: Text("Modalità Studio")) {
                    Toggle("Modalità Severa", isOn: $settingsStore.isSevereModeEnabled)
                    
                    Text("Se attiva, uscire dall'app durante una sessione Pomodoro annullerà il timer e la sessione non verrà salvata.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Impostazioni ⚙️")
        }
    }
}
