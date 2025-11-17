import SwiftUI

struct EditSessionView: View {
    // 1. Oggetti dell'ambiente
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.dismiss) var dismiss // Per chiudere la vista
    
    // 2. La sessione originale che stiamo modificando
    let session: StudySession
    
    // 3. Variabili di stato per i campi di modifica
    @State private var activityDescription: String
    @State private var durationInMinutes: Int // Mantiene i minuti per l'UI
    @State private var date: Date
    
    // 4. Inizializzatore per impostare le variabili di stato
    init(session: StudySession) {
        self.session = session
        _activityDescription = State(initialValue: session.activityDescription)
        // CORREZIONE: Inizializza i minuti dai secondi (secondi / 60)
        _durationInMinutes = State(initialValue: session.durationInSeconds / 60)
        _date = State(initialValue: session.date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dettagli Sessione")) {
                    TextField("Descrizione", text: $activityDescription)
                    
                    Stepper("Minuti: \(durationInMinutes)",
                            value: $durationInMinutes,
                            in: 1...240, // Limite da 1 min a 4 ore
                            step: 1)
                }
                
                Section(header: Text("Data e Ora")) {
                    DatePicker("Registrata il", selection: $date)
                }
            }
            .navigationTitle("Modifica Sessione")
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
                }
            }
        }
    }
    
    func saveChanges() {
        // 1. Crea una copia aggiornata della sessione
        let updatedSession = StudySession(
            id: session.id,
            date: date,
            // CORREZIONE: Converte i minuti in secondi (minuti * 60) prima di salvare
            durationInSeconds: durationInMinutes * 60,
            activityDescription: activityDescription
        )
        
        // 2. Passa la sessione aggiornata allo store
        sessionStore.updateSession(updatedSession)
        
        // 3. Chiudi la vista
        dismiss()
    }
}
