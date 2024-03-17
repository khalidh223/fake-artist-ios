import SocketIO
import SwiftUI

struct GameCodeDisplay: View {
    @ObservedObject private var globalStateManager = GlobalStateManager.shared
    @ObservedObject private var drawingWebSocket = DrawingWebSocketManager.shared
    @ObservedObject private var communicationWebSocket = CommunicationWebSocketManager.shared
    @State private var isRolePresented = false
    @State private var isStartingGame = false
    let gameCode: String
    var onCancel: () -> Void

    init(gameCode: String, onCancel: @escaping () -> Void) {
        self.gameCode = gameCode
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            if !globalStateManager.showDrawCanvasView && !globalStateManager.playerRevisitingHomeAfterGame {
                Color(red: 115.0 / 255.0, green: 5.0 / 255.0, blue: 60.0 / 255.0)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    Text("Your game code is:")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(gameCode)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom)

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

                    if globalStateManager.players.count >= 5 {
                        if isStartingGame {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(1.5, anchor: .center)
                        } else {
                            Button("Start!") {
                                isStartingGame = true
                                startGame(drawingSocket: drawingWebSocket,
                                          communicationSocket: communicationWebSocket, gameCode: gameCode)
                            }
                            .disabled(globalStateManager.players.count < 5)
                            .padding()
                            .foregroundColor(.green)
                        }
                    }

                    Button("Cancel") {
                        leaveGame(webSocketManager: communicationWebSocket,
                                  globalStateManager: globalStateManager)
                        onCancel()
                    }
                    .padding()
                    .foregroundColor(.yellow)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()

                if globalStateManager.showBlurEffect {
                    Color.clear
                        .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                }

                if isRolePresented {
                    RoleDisplayView()
                        .transition(.scale.combined(with: .opacity))
                }
            } else if globalStateManager.showDrawCanvasView {
                DrawCanvasView().transition(.opacity)
            }
        }
        .onDisappear {
            leaveGame(webSocketManager: communicationWebSocket,
                      globalStateManager: globalStateManager)
            onCancel()
        }
        .onReceive(globalStateManager.$playerRole) { role in
            guard !role.isEmpty else { return }

            withAnimation {
                globalStateManager.showBlurEffect = true
            }

            withAnimation {
                isRolePresented = true
            }
        }
        .onReceive(self.globalStateManager.$allPlayersResettedRoundState) {
            allPlayersResettedRoundState in if allPlayersResettedRoundState == true {
                isRolePresented = false
                globalStateManager.showBlurEffect = true
            }
        }
        .onReceive(self.globalStateManager.$playerRevisitingHomeAfterGame) {
            playerRevisitingHomeAfterGame in if playerRevisitingHomeAfterGame == true {
                isRolePresented = false
                globalStateManager.showBlurEffect = false
                isStartingGame = false
            }
        }
    }

    private func startGame(drawingSocket: DrawingWebSocketManager, communicationSocket: CommunicationWebSocketManager, gameCode: String) {
        print("GameCodeDisplay: Starting game with gameCode - \(gameCode)")
        drawingSocket.sendDrawingMessage("joinGame", data: gameCode)
        drawingSocket.sendDrawingMessage("startGame", data: gameCode)

        let updateGameInProgressData: [String: Any] = [
            "action": "updateGameInProgressStatus",
            "gameCode": gameCode,
            "isInProgress": true
        ]
        communicationSocket.sendCommunicationMessage(updateGameInProgressData)
    }

    private func leaveGame(webSocketManager: CommunicationWebSocketManager, globalStateManager: GlobalStateManager) {
        print("GameCodeDisplay: Leaving game with gameCode - \(gameCode)")
        webSocketManager.sendLeaveGameMessage(gameCode: gameCode, username: globalStateManager.username)
    }
}
