import SwiftUI

struct EditGoalView: View {
    // 1. Oggetti dell'ambiente
    @EnvironmentObject var store: GoalsStore
    @Environment(\.dismiss) var dismiss
    
    // 2. L'obiettivo originale che stiamo modificando
    let goal: Goal
    
    // 3. Variabili di stato per i campi di modifica
    @State private var newTitle: String
    @State private var newPomodorosTarget: Int
    
    // 4. Inizializzatore per impostare le variabili di stato
    init(goal: Goal) {
        self.goal = goal
        _newTitle = State(initialValue: goal.title)
        _newPomodorosTarget = State(initialValue: goal.pomodorosTarget)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dettagli Obiettivo")) {
                    TextField("Titolo", text: $newTitle)
                    
                    Stepper("Pomodori Target: \(newPomodorosTarget)",
                            value: $newPomodorosTarget,
                            in: 1...20) // Puoi cambiare il range
                }
            }
            .navigationTitle("Modifica Obiettivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Bottone per annullare
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                // Bottone per salvare
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty) // Disabilita se il titolo è vuoto
                }
            }
        }
    }
    
    func saveChanges() {
        // 1. Crea una copia aggiornata dell'obiettivo
        let updatedGoal = Goal(
            id: goal.id,
            title: newTitle,
            isCompleted: goal.isCompleted,
            pomodorosTarget: newPomodorosTarget,
            pomodorosCompleted: goal.pomodorosCompleted // Mantiene i pomodori già completati
        )
        
        // 2. Passa l'obiettivo aggiornato allo store
        store.updateGoal(updatedGoal)
        
        // 3. Chiudi la vista
        dismiss()
    }
}
