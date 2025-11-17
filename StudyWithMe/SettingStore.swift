import Foundation
import Combine

class SettingsStore: ObservableObject {
    
    // Definiamo le chiavi per il salvataggio
    private let pomodoroKey = "pomodoroDuration"
    private let shortBreakKey = "shortBreakDuration"
    private let longBreakKey = "longBreakDuration"
    private let severeModeKey = "isSevereModeEnabled"
    private let pomodorosBeforeLongBreakKey = "pomodorosBeforeLongBreak"
    
    @Published var pomodoroMinutes: Int {
        didSet {
            UserDefaults.standard.set(pomodoroMinutes, forKey: pomodoroKey)
        }
    }
    
    @Published var shortBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(shortBreakMinutes, forKey: shortBreakKey)
        }
    }
    
    @Published var longBreakMinutes: Int {
        didSet {
            UserDefaults.standard.set(longBreakMinutes, forKey: longBreakKey)
        }
    }
    
    @Published var isSevereModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSevereModeEnabled, forKey: severeModeKey)
        }
    }
    
    // NUOVA IMPOSTAZIONE
    @Published var pomodorosBeforeLongBreak: Int {
        didSet {
            UserDefaults.standard.set(pomodorosBeforeLongBreak, forKey: pomodorosBeforeLongBreakKey)
        }
    }
    
    init() {
        // Carichiamo i valori salvati all'avvio
        
        let savedPomodoro = UserDefaults.standard.integer(forKey: pomodoroKey)
        self.pomodoroMinutes = (savedPomodoro == 0) ? 25 : savedPomodoro
        
        let savedShort = UserDefaults.standard.integer(forKey: shortBreakKey)
        self.shortBreakMinutes = (savedShort == 0) ? 5 : savedShort
        
        let savedLong = UserDefaults.standard.integer(forKey: longBreakKey)
        self.longBreakMinutes = (savedLong == 0) ? 15 : savedLong
        
        // Carica la nuova impostazione (default 4)
        let savedPomodorosBeforeLongBreak = UserDefaults.standard.integer(forKey: pomodorosBeforeLongBreakKey)
        self.pomodorosBeforeLongBreak = (savedPomodorosBeforeLongBreak == 0) ? 4 : savedPomodorosBeforeLongBreak
        
        self.isSevereModeEnabled = UserDefaults.standard.bool(forKey: severeModeKey)
    }
}
