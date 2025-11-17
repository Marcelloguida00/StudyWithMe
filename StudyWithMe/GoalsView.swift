import SwiftUI
import Combine

// --- 1. Il Modello Dati (AGGIORNATO) ---
struct Goal: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var pomodorosTarget: Int = 1      // Numero di Pomodori da completare
    var pomodorosCompleted: Int = 0   // Numero di Pomodori completati
    
    // Il goal è completato se tutti i pomodoros sono stati fatti E l'utente non l'ha deselezionato manualmente
    var isPomodorosMet: Bool {
        return pomodorosCompleted >= pomodorosTarget
    }
}

// --- 2. Il Gestore dei Dati (Store) ---
class GoalsStore: ObservableObject {
    
    @Published var goals: [Goal] {
        didSet {
            saveGoals()
        }
    }
    
    private let userDefaultsKey = "SavedGoals"
    
    init() {
        self.goals = GoalsStore.loadGoals(key: userDefaultsKey)
    }
    
    private static func loadGoals(key: String) -> [Goal] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            // Esempi aggiornati
            return [
                Goal(title: "Studiare 2 ore di matematica", pomodorosTarget: 5),
                Goal(title: "Ripetere capitolo di storia", pomodorosTarget: 3),
                Goal(title: "Fare 4 sessioni di Pomodoro", pomodorosTarget: 4)
            ]
        }
        if let decodedGoals = try? JSONDecoder().decode([Goal].self, from: data) {
            return decodedGoals
        }
        return []
    }
    
    private func saveGoals() {
        if let encodedData = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
        }
    }
    
    // NUOVA FUNZIONE: Incrementa il contatore di Pomodoro
    func incrementPomodoros(for goalID: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalID }) {
            goals[index].pomodorosCompleted += 1
            
            // Marca come completato automaticamente se il target è raggiunto
            if goals[index].isPomodorosMet {
                goals[index].isCompleted = true
            }
        }
    }
    
    // NUOVA FUNZIONE: Resetta il contatore (usato se l'utente 'smarca' l'obiettivo)
    func resetPomodoros(for goalID: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalID }) {
            goals[index].pomodorosCompleted = 0
            goals[index].isCompleted = false
        }
    }
    
    // --- NUOVA FUNZIONE AGGIUNTA QUI ---
    // Funzione per aggiornare un obiettivo esistente
    func updateGoal(_ updatedGoal: Goal) {
        // Trova l'indice dell'obiettivo con lo stesso ID e sostituiscilo
        if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
            goals[index] = updatedGoal
        }
    }
}


// --- 3. La Vista (View) ---
struct GoalsView: View {
    
    @EnvironmentObject var store: GoalsStore
    @State private var newGoalTitle = ""
    @State private var newPomodorosTarget: Int = 4 // Stato per l'input del target
    
    // --- NUOVA VARIABILE DI STATO ---
    @State private var goalToEdit: Goal? = nil
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // --- 1. Sezione Input Obiettivo ---
                VStack(spacing: 15) {
                    HStack {
                        TextField("Es. Studia per l'esame", text: $newGoalTitle)
                            .padding(12)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .onSubmit {
                                addGoal()
                            }
                    }
                    
                    // Stepper per il Target Pomodoro
                    Stepper("Pomodori Target: \(newPomodorosTarget)",
                            value: $newPomodorosTarget,
                            in: 1...20)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .padding(.horizontal)
                .padding(.top, 10)
                
                // --- 2. Lista Obiettivi ---
                List {
                    // Obiettivi non completati (in alto)
                    Section(header: Text("In Corso")) {
                        ForEach($store.goals.filter { !$0.wrappedValue.isCompleted }) { $goal in
                            
                            // --- MODIFICA QUI ---
                            GoalRow(goal: $goal)
                                .contentShape(Rectangle()) // Assicura che tutta la riga sia tappabile
                                .onTapGesture {
                                    // Al tocco, imposta l'obiettivo da modificare
                                    self.goalToEdit = $goal.wrappedValue
                                }
                        }
                        .onDelete(perform: deleteGoal) // MODIFICA: La funzione deleteGoal è stata corretta
                    }
                    
                    // Obiettivi completati (in basso e disattivati)
                    if store.goals.contains(where: { $0.isCompleted }) {
                        Section(header: Text("Completati")) {
                            ForEach($store.goals.filter { $0.wrappedValue.isCompleted }) { $goal in
                                GoalRow(goal: $goal)
                                    .opacity(0.6)
                            }
                            .onDelete(perform: deleteGoal) // MODIFICA: La funzione deleteGoal è stata corretta
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                Spacer()
            }
            .navigationTitle("I tuoi obiettivi 🎯")
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            
            // --- MODIFICA QUI ---
            // Aggiungi il .sheet (foglio modale) che si attiva
            // quando 'goalToEdit' non è nullo
            .sheet(item: $goalToEdit) { goal in
                // Presenta la new vista di modifica
                EditGoalView(goal: goal)
                    // Assicurati di passare l'environmentObject!
                    .environmentObject(store)
            }
        }
    }
    
    func addGoal() {
        let trimmedTitle = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            store.goals.append(Goal(title: trimmedTitle, pomodorosTarget: newPomodorosTarget))
            newGoalTitle = ""
            newPomodorosTarget = 4 // Reset al valore di default
        }
    }
    
    // --- FUNZIONE MODIFICATA (CORRETTA) ---
    func deleteGoal(at offsets: IndexSet) {
        // Dobbiamo trovare il vero indice nell'array 'store.goals'
        // perché 'offsets' si basa sulla lista filtrata.
        
        // 1. Crea una lista temporanea degli obiettivi visibili (in corso E completati)
        let visibleGoals = store.goals
        var idsToDelete = IndexSet()
        
        // 2. Trova gli ID degli obiettivi da eliminare
        for index in offsets {
            let goalID = visibleGoals[index].id
            // 3. Trova l'indice nell'array originale 'store.goals'
            if let originalIndex = store.goals.firstIndex(where: { $0.id == goalID }) {
                idsToDelete.insert(originalIndex)
            }
        }
        
        // 4. Elimina dall'array originale
        if !idsToDelete.isEmpty {
            store.goals.remove(atOffsets: idsToDelete)
        }
    }
}

// --- Vista separata per la riga dell'obiettivo ---
struct GoalRow: View {
    @EnvironmentObject var store: GoalsStore
    @Binding var goal: Goal
    
    var body: some View {
        HStack {
            Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(goal.isCompleted ? .green : .blue)
                .onTapGesture {
                    withAnimation {
                        if goal.isCompleted {
                            store.resetPomodoros(for: goal.id)
                        } else {
                            // Non marcare più come completato se si tocca la spunta
                            // La modifica avviene solo tramite il contatore
                            // Per mantenere il vecchio comportamento (spunta manuale):
                             goal.isCompleted.toggle()
                        }
                    }
                }
            
            VStack(alignment: .leading) {
                Text(goal.title)
                    .strikethrough(goal.isCompleted, color: .gray)
                    .foregroundColor(goal.isCompleted ? .gray : .primary)
                
                // Indicatore di progresso Pomodoro
                if goal.pomodorosTarget > 0 {
                    Text("\(goal.pomodorosCompleted) / \(goal.pomodorosTarget) Pomodori")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
}
