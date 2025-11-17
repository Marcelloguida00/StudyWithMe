import Foundation
import SwiftUI
import Combine

struct StudySession: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var durationInSeconds: Int
    var activityDescription: String
}

class SessionStore: ObservableObject {
    
    private var isSorting = false
    
    @Published var sessions: [StudySession] {
        didSet {
            guard !isSorting else { return }
            isSorting = true
            sessions.sort(by: { $0.date > $1.date })
            isSorting = false
            saveSessions()
        }
    }
    
    private let userDefaultsKey = "SavedStudySessions"
    
    init() {
        self.sessions = SessionStore.loadSessions(key: userDefaultsKey)
    }
    
    func addSession(durationInSeconds: Int, description: String) {
        let newSession = StudySession(
            date: Date(),
            durationInSeconds: durationInSeconds,
            activityDescription: description
        )
        sessions.insert(newSession, at: 0)
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
    }
    
    func updateSession(_ updatedSession: StudySession) {
        guard let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) else {
            return
        }
        sessions[index] = updatedSession
    }

    func deleteAllSessions() {
        sessions.removeAll()
    }

    private static func loadSessions(key: String) -> [StudySession] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        if let decodedSessions = try? JSONDecoder().decode([StudySession].self, from: data) {
            return decodedSessions
        }
        return []
    }
    
    private func saveSessions() {
        if let encodedData = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
        }
    }
}
