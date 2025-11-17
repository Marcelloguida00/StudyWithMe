import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var sessionStore: SessionStore
    
    // Stato per tracciare quale sessione modificare
    @State private var sessionToEdit: StudySession? = nil

    var body: some View {
        NavigationStack {
            VStack {
                if sessionStore.sessions.isEmpty {
                    
                    // Messaggio per lista vuota
                    Spacer()
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.7))
                    Text("Nessuna sessione")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("Completa una sessione di studio per vederla qui.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                    
                } else {
                    
                    // Lista delle sessioni
                    List {
                        ForEach(sessionStore.sessions) { session in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(session.activityDescription)
                                    .font(.headline)
                                
                                HStack {
                                    // CORREZIONE: Mostra i minuti dividendo i secondi per 60
                                    Text("\(session.durationInSeconds / 60) minuti")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                            .contentShape(Rectangle()) // Rende tutta l'area tappabile
                            .onTapGesture {
                                // Al tocco, imposta la sessione da modificare
                                self.sessionToEdit = session
                            }
                        }
                        .onDelete(perform: deleteSession)
                    }
                }
            }
            .navigationTitle("Cronologia Studio 📖")
            .toolbar {
                if !sessionStore.sessions.isEmpty {
                    EditButton()
                }
            }
            // Foglio modale che si attiva quando 'sessionToEdit' non è nullo
            .sheet(item: $sessionToEdit) { session in
                // Presenta la nuova vista di modifica
                EditSessionView(session: session)
                    .environmentObject(sessionStore)
            }
        }
    }
    
    // Funzione helper per chiamare lo store
    private func deleteSession(at offsets: IndexSet) {
        sessionStore.deleteSession(at: offsets)
    }
}
