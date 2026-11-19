import SwiftUI

struct MacroAction: Identifiable, Codable {
    let id = UUID()
    enum Kind: String, Codable { case tap, swipe }
    let kind: Kind
    let x: CGFloat
    let y: CGFloat
    let endX: CGFloat?
    let endY: CGFloat?
    let delay: Double
}

struct ContentView: View {
    @State private var actions: [MacroAction] = []
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var status = "Ready"

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.75), .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text("IN-APP MACRO")
                    .font(.headline).foregroundStyle(.white)
                Text(status).foregroundStyle(.white.opacity(0.8))
                Spacer()

                HStack(spacing: 16) {
                    ControlButton(title: isRecording ? "Stop" : "Record", color: .red) {
                        isRecording.toggle()
                        if isRecording { actions.removeAll(); status = "Recording—tap or swipe below" }
                        else { status = "Saved \(actions.count) actions" }
                    }
                    ControlButton(title: "Playback", color: .green) { play() }
                    ControlButton(title: "Clear", color: .gray) { actions.removeAll(); status = "Ready" }
                }
            }

            GestureCapture(actions: $actions, isRecording: $isRecording)
                .allowsHitTesting(isRecording)
        }
    }

    func play() {
        guard !actions.isEmpty, !isPlaying else { status = "Nothing to play or already playing"; return }
        isPlaying = true
        status = "Playing…"
        Task { @MainActor in
            for action in actions {
                try? await Task.sleep(nanoseconds: UInt64(action.delay * 1_000_000_000))
                withAnimation(.easeInOut(duration: 0.25)) {
                    status = action.kind == .tap ? "Tap" : "Swipe"
                }
            }
            isPlaying = false
            status = "Playback complete"
        }
    }
}

struct ControlButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).bold().foregroundStyle(.white)
                .padding(.vertical, 12).padding(.horizontal, 16)
                .background(color).clipShape(Capsule())
        }
    }
}

struct GestureCapture: View {
    @Binding var actions: [MacroAction]
    @Binding var isRecording: Bool
    @State private var start: CGPoint?

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if start == nil { start = value.startLocation }
                }
                .onEnded { value in
                    guard isRecording else { return }
                    let distance = hypot(value.startLocation.x - value.location.x, value.startLocation.y - value.location.y)
                    let action: MacroAction
                    if distance < 12 {
                        action = MacroAction(kind: .tap, x: value.location.x, y: value.location.y, endX: nil, endY: nil, delay: 0.3)
                    } else {
                        action = MacroAction(kind: .swipe, x: value.startLocation.x, y: value.startLocation.y, endX: value.location.x, endY: value.location.y, delay: 0.5)
                    }
                    actions.append(action)
                    start = nil
                })
    }
}
