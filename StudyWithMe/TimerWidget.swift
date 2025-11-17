import WidgetKit
import SwiftUI
import ActivityKit

@main
struct TimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            
            // --- UI per la Schermata di Blocco (Lock Screen) ---
            HStack(spacing: 15) {
                // Icona e Progresso
                ZStack {
                    // NOTA: Usiamo una versione leggermente modificata di
                    // CircularProgressView per la lock screen.
                    // (Si basa sul file originale condiviso)
                    ZStack {
                        let clamped = min(max(context.state.progress, 0), 1)
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                        
                        Circle()
                            .trim(from: 0.0, to: clamped)
                            .stroke(
                                AngularGradient(gradient: Gradient(colors: [.red, .orange]),
                                              center: .center),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 60, height: 60)
                    
                    
                    Image(systemName: context.attributes.timerName == "Pomodoro" ? "brain.head.profile" : "cup.and.saucer")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                // Testo
                VStack(alignment: .leading) {
                    Text(context.attributes.timerName) // "Pomodoro" o "Pausa"
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Il timer che conta alla rovescia
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.largeTitle)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.3)) // Sfondo per la lock screen
            
        } dynamicIsland: { context in
            
            // --- UI per la Dynamic Island ---
            DynamicIsland {
                // Vista Espansa
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.timerName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 50)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(.orange)
                }
            } compactLeading: {
                // Isola compatta (sinistra)
                Image(systemName: context.attributes.timerName == "Pomodoro" ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // Isola compatta (destra)
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 45)
            } minimal: {
                // Icona AOD (Always On Display)
                Image(systemName: context.attributes.timerName == "Pomodoro" ? "brain.head.profile" : "cup.and.saucer")
                    .foregroundColor(.orange)
            }
        }
    }
}
