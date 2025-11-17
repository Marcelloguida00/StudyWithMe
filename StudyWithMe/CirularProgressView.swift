import SwiftUI

struct CircularProgressView: View {
    var progress: Double // da 0.0 a 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        let clamped = min(max(progress, 0), 1)
        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            
            Circle()
                .trim(from: 0.0, to: clamped)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [.red, .orange]),
                                    center: .center),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: progress)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avanzamento")
        .accessibilityValue(Text("\(Int(clamped * 100))%"))
    }
}
