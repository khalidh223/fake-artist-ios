import SwiftUI

struct HomeButton: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .foregroundColor(Color.black.opacity(0.001))
                .frame(height: 30)
                .overlay(
                    Text(text)
                )
        }
        .buttonStyle(OutlineButtonStyle(borderColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), textColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), borderWidth: 1))
        .padding(.bottom)
    }
}

struct Home: View {
    @ObservedObject private var drawingWebSocket = DrawingWebSocketManager.shared
    @ObservedObject private var communicationWebSocket = CommunicationWebSocketManager.shared
    @ObservedObject private var globalStateManager = GlobalStateManager.shared
    @State private var showNewGameSheet = false
    @State private var showJoinGameSheet = false
    @State private var gameCode: String?
    @State private var navigateToJoinGamePlayers = false

    var body: some View {
        ZStack {
            Color(red: 115.0 / 255.0, green: 5.0 / 255.0, blue: 60.0 / 255.0)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Image("logo")
                    .padding()
                    .padding()

                HomeButton(text: "NEW GAME", action: { showNewGameSheet = true })
                    .sheet(isPresented: $showNewGameSheet) {
                        NewGameSheet(isPresented: $showNewGameSheet) { code in
                            self.gameCode = code
                        }
                    }

                HomeButton(text: "JOIN GAME", action: { showJoinGameSheet = true })
                    .sheet(isPresented: $showJoinGameSheet) {
                        JoinGameSheet(isPresented: $showJoinGameSheet, onJoinGame: {
                            showJoinGameSheet = false // Dismiss the JoinGameSheet
                            navigateToJoinGamePlayers = true // Trigger navigation to JoinGamePlayers
                        })
                    }
            }

            if navigateToJoinGamePlayers {
                JoinGamePlayers() {
                    navigateToJoinGamePlayers = false
                    drawingWebSocket.closeDrawingSocketConnection()
                    communicationWebSocket.disconnect()
                    globalStateManager.players.removeAll()
                    globalStateManager.setUsername(usernameToSet: "")
                    globalStateManager.setGameCode(gameCodeToSet: "")
                }
            }

            if let gameCode = gameCode {
                GameCodeDisplay(gameCode: gameCode) {
                    self.gameCode = nil
                    drawingWebSocket.closeDrawingSocketConnection()
                    communicationWebSocket.disconnect()
                    globalStateManager.players.removeAll()
                    globalStateManager.setUsername(usernameToSet: "")
                    globalStateManager.setGameCode(gameCodeToSet: "")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
