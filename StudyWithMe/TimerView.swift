import SwiftUI
import AVFoundation
import UserNotifications
import ActivityKit // <-- IMPORTANTE
import Combine

struct TimerView: View {
    // Gestori
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var goalsStore: GoalsStore
    @EnvironmentObject var settingsStore: SettingsStore
    
    // Stato dell'app
    @Environment(\.scenePhase) private var scenePhase

    // Stati del timer (tutto in secondi)
    @State private var totalTime: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var timerRunning = false
    @State private var timer: Timer?
    @State private var selectedGoalID: UUID? = nil
    
    // Contatore per la Pausa Lunga
    @AppStorage("pomodoroCountInCycle") private var pomodoroCountInCycle: Int = 0
    
    // Stati Modalità Severa
    @State private var backgroundEntryTime: Date? = nil
    @State private var showingPenaltyAlert = false
    
    // STATO: per l'alert di completamento
    @State private var showingCompletionAlert = false
    
    @State private var audioPlayer: AVAudioPlayer?
    
    // --- STATO PER LIVE ACTIVITY ---
    @State private var currentActivity: Activity<TimerActivityAttributes>? = nil
    
    // MARK: - Proprietà Calcolate per le Statistiche
    
    var todaysStudyTimeInSeconds: Int {
        sessionStore.sessions
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.durationInSeconds }
    }
    
    var todaysPomodorosCompleted: Int {
        sessionStore.sessions
            .filter {
                Calendar.current.isDateInToday($0.date) &&
                $0.durationInSeconds == settingsStore.pomodoroMinutes * 60
            }
            .count
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                
                Text("Pomodoro Focus")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .padding(.top)
                
                // --- Selettore Obiettivo ---
                VStack {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.gray)
                        Text("Obiettivo Attuale:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("Seleziona Obiettivo", selection: $selectedGoalID) {
                            Text("🎯 Nessun obiettivo").tag(nil as UUID?)
                            ForEach(goalsStore.goals.filter { !$0.isPomodorosMet }) { goal in
                                Text(goal.title).tag(goal.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.bottom, 20)
                

                // --- Timer e Progress View ---
                ZStack {
                    CircularProgressView(progress: progress)
                        .frame(width: 250, height: 250)
                    
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        // --- 1. MODIFICA ANIMAZIONE ---
                        .contentTransition(.numericText())
                }
                .padding(.bottom, 40)
                
                // --- Statistiche Giornaliere ---
                HStack(spacing: 15) {
                    StatCard(
                        value: formatStudyTime(todaysStudyTimeInSeconds),
                        label: "Tempo Oggi",
                        icon: "clock.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        value: "\(todaysPomodorosCompleted)",
                        label: "Pomodori Oggi",
                        icon: "checkmark.seal.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                Text("Ciclo Pomodoro: \(pomodoroCountInCycle) / \(settingsStore.pomodorosBeforeLongBreak)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                    // --- 2. MODIFICA ANIMAZIONE (Opzionale) ---
                    .contentTransition(.numericText())
                
                // --- Controlli Timer ---
                HStack(spacing: 30) {
                    Button(action: startTimer) { CircleButton(icon: "play.fill", color: .green) }
                        .disabled(timerRunning)
                    
                    Button(action: pauseTimer) { CircleButton(icon: "pause.fill", color: .yellow) }
                        .disabled(!timerRunning)
                    
                    Button(action: { resetTimer() }) { CircleButton(icon: "stop.fill", color: .red) }
                }
                .padding(.bottom, 40)
                
                // --- Selettore Modalità ---
                VStack(alignment: .leading) {
                    Text("Seleziona Modalità")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                    
                    HStack(spacing: 10) {
                        ModeButton(
                            label: "Pomodoro",
                            minutes: settingsStore.pomodoroMinutes,
                            color: .red,
                            isStudy: true)
                        
                        ModeButton(
                            label: "Pausa Corta",
                            minutes: settingsStore.shortBreakMinutes,
                            color: .blue,
                            isStudy: false)
                        
                        ModeButton(
                            label: "Pausa Lunga",
                            minutes: settingsStore.longBreakMinutes,
                            color: .green,
                            isStudy: false)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        
        // Alert per Modalità Severa
        .alert("Sessione Annullata!", isPresented: $showingPenaltyAlert) {
            Button("Ho capito", role: .cancel) { }
        } message: {
            Text("Sei stato via per più di 10 secondi in Modalità Severa. Il timer è stato resettato.")
        }
        
        // Alert per Completamento (Salva al click di OK)
        .alert("Sessione Completata!", isPresented: $showingCompletionAlert) {
            Button("OK", role: .cancel) {
                // Avvolgi in animazione anche il cambio di statistiche
                withAnimation {
                    logCompletedSession()
                }
            }
        } message: {
            Text("Hai completato la tua sessione!")
        }
        
        .onAppear {
            if !timerRunning && timeRemaining == 0 {
                setMode(minutes: settingsStore.pomodoroMinutes, isStudy: true, logSession: false)
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        
        .onChange(of: scenePhase) { oldPhase, newPhase in
            
            if newPhase == .inactive || newPhase == .background {
                
                // --- CORREZIONE BUG MODALITÀ SEVERA ---
                if settingsStore.isSevereModeEnabled && timerRunning && isStudySession() {
                    
                    if backgroundEntryTime == nil {
                        backgroundEntryTime = Date()
                    }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["penalty_warning"])
                    scheduleNotification()
                }
                
            } else if newPhase == .active {
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["penalty_warning"])
                
                if let entryTime = backgroundEntryTime {
                    
                    let timeInBackground = Date().timeIntervalSince(entryTime)
                    
                    if timeInBackground > 10 {
                        resetTimer(logSession: false)
                        showingPenaltyAlert = true
                        
                    } else if timerRunning {
                        timer?.invalidate()
                        timerRunning = false
                        
                        timeRemaining -= Int(ceil(timeInBackground))
                        
                        if timeRemaining <= 0 {
                            timeRemaining = 0
                            handleTimerCompletion()
                        } else {
                            startTimer() // Riavvia
                        }
                    }
                    backgroundEntryTime = nil
                }
            }
        }
    }


    // MARK: - Funzioni Helper
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return (Double(totalTime) - Double(timeRemaining)) / Double(totalTime)
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatStudyTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    private func logInterruptedSession() {
        let elapsedSeconds = totalTime - timeRemaining
        guard elapsedSeconds >= 15 else { return }
        guard isStudySession() else { return }
        
        let description = selectedGoalID.flatMap { id in
            goalsStore.goals.first { $0.id == id }?.title
        } ?? "Studio"
        
        sessionStore.addSession(
            durationInSeconds: elapsedSeconds,
            description: description
        )
    }

    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Modalità Severa Attiva!"
        content.body = "Torna all'app entro 10 secondi o la tua sessione di studio verrà annullata."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "penalty_warning", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func logCompletedSession() {
        let duration = totalTime
        let wasStudy = isStudySession()
        
        let description: String
        if let goalID = selectedGoalID,
           let goal = goalsStore.goals.first(where: { $0.id == goalID }) {
            description = goal.title
            if wasStudy {
                goalsStore.incrementPomodoros(for: goalID)
            }
        } else {
            description = wasStudy ? "Studio" : "Pausa"
        }
        
        sessionStore.addSession(
            durationInSeconds: duration,
            description: description
        )
        
        // Logica transizione
        if wasStudy {
            pomodoroCountInCycle += 1
            if pomodoroCountInCycle >= settingsStore.pomodorosBeforeLongBreak {
                pomodoroCountInCycle = 0
                setMode(minutes: settingsStore.longBreakMinutes, isStudy: false, logSession: false)
            } else {
                setMode(minutes: settingsStore.shortBreakMinutes, isStudy: false, logSession: false)
            }
        } else {
            if totalTime == settingsStore.longBreakMinutes * 60 {
                pomodoroCountInCycle = 0
            }
            setMode(minutes: settingsStore.pomodoroMinutes, isStudy: true, logSession: false)
        }
    }
    
    func handleTimerCompletion() {
        stopActivity() // <-- LIVE ACTIVITY
        timer?.invalidate()
        timerRunning = false
        playSound()
        showingCompletionAlert = true
    }
    
    func isStudySession() -> Bool {
        return totalTime == settingsStore.pomodoroMinutes * 60
    }
    
    // MARK: - Funzioni Timer
    func startTimer() {
        if timeRemaining == 0 {
            setMode(minutes: settingsStore.pomodoroMinutes, isStudy: true, logSession: false)
        }
        guard !timerRunning else { return }
        
        startActivity() // <-- LIVE ACTIVITY
        
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.timeRemaining > 0 {
                
                // --- 3. MODIFICA CHIAVE PER L'ANIMAZIONE ---
                // Avvolgiamo la modifica del tempo in un blocco
                // 'withAnimation' per farla animare.
                withAnimation(.default) {
                    self.timeRemaining -= 1
                }
                
                self.updateActivity(progress: self.progress) // Aggiorna Live Activity
            } else {
                self.handleTimerCompletion()
            }
        }
    }

    func pauseTimer() {
        timer?.invalidate()
        timerRunning = false
    }

    func resetTimer(logSession: Bool = true) {
        stopActivity() // <-- LIVE ACTIVITY
        if logSession {
            logInterruptedSession()
        }
        timer?.invalidate()
        timerRunning = false
        
        // Aggiungi animazione anche al reset
        withAnimation {
            totalTime = settingsStore.pomodoroMinutes * 60
            timeRemaining = totalTime
        }
    }

    func setMode(minutes: Int, isStudy: Bool, logSession: Bool = true) {
        stopActivity() // <-- LIVE ACTIVITY
        if logSession {
            logInterruptedSession()
        }
        timer?.invalidate()
        timerRunning = false
        
        // Aggiungi animazione anche al cambio modalità
        withAnimation {
            totalTime = minutes * 60
            timeRemaining = totalTime
        }
        
        if !isStudy {
            selectedGoalID = nil
        }
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(1304)
    }
    
    // MARK: - Funzioni Gestione Live Activity
    
    func getCurrentTimerName() -> String {
        if totalTime == settingsStore.pomodoroMinutes * 60 {
            return "Pomodoro"
        } else if totalTime == settingsStore.shortBreakMinutes * 60 {
            return "Pausa Corta"
        } else if totalTime == settingsStore.longBreakMinutes * 60 {
            return "Pausa Lunga"
        }
        return "Sessione"
    }

    // --- FUNZIONE CORRETTA (iOS 16.2+) ---
    func startActivity() {
        stopActivity() // Cancella la precedente
        
        let attributes = TimerActivityAttributes(timerName: getCurrentTimerName())
        let endTime = Date().addingTimeInterval(TimeInterval(timeRemaining))
        
        // 1. Crea lo stato
        let contentState = TimerActivityAttributes.ContentState(endTime: endTime, progress: progress)
        
        // 2. CORREZIONE: Crea l'oggetto ActivityContent
        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            currentActivity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: content, // 3. Passa l'oggetto ActivityContent
                pushType: nil
            )
        } catch (let error) {
            print("Errore avviando Live Activity: \(error.localizedDescription)")
        }
    }

    // --- FUNZIONE CORRETTA (iOS 16.2+) ---
    func updateActivity(progress: Double) {
        guard let activity = currentActivity else { return }
        
        // 1. Prendi l'ora di fine (ora è in 'activity.content.state')
        let endTime = activity.content.state.endTime
        
        // 2. Crea il *nuovo* stato
        let newState = TimerActivityAttributes.ContentState(
            endTime: endTime,
            progress: progress
        )
        
        // 3. CORREZIONE: Crea il *nuovo* oggetto ActivityContent
        let newContent = ActivityContent(state: newState, staleDate: nil)
        
        Task {
            // 4. Passa l'oggetto ActivityContent
            await activity.update(newContent)
        }
    }

    func stopActivity() {
        Task {
            // Questa funzione va bene, la lasciamo com'è
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    
    // MARK: - Subviews
    
    struct StatCard: View {
        var value: String
        var label: String
        var icon: String
        var color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    Spacer()
                }
                Text(value)
                    .font(.title.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    // --- 4. MODIFICA ANIMAZIONE (Opzionale) ---
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    func ModeButton(label: String, minutes: Int, color: Color, isStudy: Bool) -> some View {
        Button(action: { setMode(minutes: minutes, isStudy: isStudy, logSession: true) }) {
            Text(label)
                .font(.subheadline.bold())
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(color)
                .clipShape(Capsule())
        }
    }
    
    func CircleButton(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.title)
            .foregroundColor(.white)
            .frame(width: 65, height: 65)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}
