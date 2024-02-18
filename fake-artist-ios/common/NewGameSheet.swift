import SwiftUI

struct NewGameSheet: View {
    @ObservedObject private var drawingWebSocket = DrawingWebSocketManager.shared
    @ObservedObject private var communicationWebSocket = CommunicationWebSocketManager.shared
    @ObservedObject private var globalStateManager = GlobalStateManager.shared
    @Binding var isPresented: Bool
    var onGameCodeFetched: (String) -> Void = { _ in }
    @State private var username: String = ""
    @FocusState private var isUsernameFieldFocused: Bool
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("Enter your username!")
                    .font(.title2)
                    .bold()
                    .padding()

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disabled(isLoading)
                    .focused($isUsernameFieldFocused)
                    .padding()

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5, anchor: .center)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }

                Spacer()
            }
            .navigationBarItems(trailing: Button("Next") {
                globalStateManager.setUsername(usernameToSet: username)
                fetchGameCode(globalStateManager: globalStateManager)
            }
            .disabled(username.isEmpty || isLoading))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isUsernameFieldFocused = true
                }

                if !drawingWebSocket.isDrawingSocketConnected {
                    drawingWebSocket.establishDrawingSocketConnection()
                }

                if !communicationWebSocket.isCommunicationSocketConnected {
                    communicationWebSocket.setupCommunicationSocket()
                }
            }
        }
    }

    private func fetchGameCode(globalStateManager: GlobalStateManager) {
        let url = URL(string: ProcessInfo.processInfo.environment["FETCH_GAME_CODE_URL"] ?? "No url defined")!

        let body: [String: String] = ["username": username]
        guard let jsonData = try? JSONEncoder().encode(body) else {
            print("Failed to encode username")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        isLoading = true // Start loading

        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { DispatchQueue.main.async { self.isLoading = false } }

            if let data = data,
               let decodedResponse = try? JSONDecoder().decode(GameCodeResponse.self, from: data)
            {
                DispatchQueue.main.async {
                    self.onGameCodeFetched(decodedResponse.gameCode)
                    self.sendCreateGameMessage(gameCode: decodedResponse.gameCode)
                    globalStateManager.addPlayer(player: username)
                    globalStateManager.setGameCode(gameCodeToSet: decodedResponse.gameCode)
                    self.isPresented = false
                }
            } else {
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }

    private func sendCreateGameMessage(gameCode: String) {
        let messageData: [String: Any] = [
            "action": "createGame",
            "gameCode": gameCode,
            "username": username
        ]
        communicationWebSocket.sendCommunicationMessage(messageData)
    }
}

struct GameCodeResponse: Codable {
    let gameCode: String
}
