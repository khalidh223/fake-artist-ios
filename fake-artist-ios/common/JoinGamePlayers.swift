import SwiftUI

struct JoinGamePlayers: View {
    @ObservedObject private var globalStateManager = GlobalStateManager.shared
    @ObservedObject private var communicationWebSocketManager = CommunicationWebSocketManager.shared
    @ObservedObject private var drawingWebSocketManager = DrawingWebSocketManager.shared
    @State private var showGameEndedAlert = false
    @State private var isRolePresented = false
    @State private var showBlurEffect = false

    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color(red: 115.0 / 255.0, green: 5.0 / 255.0, blue: 60.0 / 255.0)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer() // Pushes content to the center

                Text("Waiting for host to start game...")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ScrollView {
                    VStack {
                        ForEach(globalStateManager.players, id: \.self) { player in
                            Text(player)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Spacer()

                Button("Cancel") {
                    leaveGame(webSocketManager: communicationWebSocketManager,
                              globalStateManager: globalStateManager)
                    onCancel()
                }
                .padding()
                .foregroundColor(.yellow)
            }

            if showBlurEffect {
                // Blurry glass-like background
                Color.clear
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }

            if isRolePresented {
                // Role display view
                RoleDisplayView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            let messageData: [String: Any] = [
                "action": "joinGame",
                "gameCode": globalStateManager.gameCode,
                "username": globalStateManager.username
            ]
            communicationWebSocketManager.sendCommunicationMessage(messageData)
            drawingWebSocketManager.sendDrawingMessage("joinGame", data: globalStateManager.gameCode)
        }
        .onDisappear {
            leaveGame(webSocketManager: communicationWebSocketManager,
                      globalStateManager: globalStateManager)
            onCancel()
        }
        .onReceive(globalStateManager.$gameEnded) { gameEnded in
            if gameEnded {
                showGameEndedAlert = true
            }
        }
        .alert(isPresented: $showGameEndedAlert) {
            Alert(
                title: Text("The host has ended the game"),
                dismissButton: .default(Text("Exit")) {
                    onCancel()
                }
            )
        }
        .onReceive(globalStateManager.$playerRole) { role in
            guard !role.isEmpty else { return }

            withAnimation {
                showBlurEffect = true
            }

            // Delay the presentation of the role view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isRolePresented = true
                }
            }
        }
    }

    private func leaveGame(webSocketManager: CommunicationWebSocketManager, globalStateManager: GlobalStateManager) {
        webSocketManager.sendLeaveGameMessage(gameCode: globalStateManager.gameCode, username: globalStateManager.username)
    }
}

