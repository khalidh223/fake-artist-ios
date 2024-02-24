import Combine
import SwiftUI

struct JoinGameSheet: View {
    @ObservedObject private var drawingWebSocket = DrawingWebSocketManager.shared
    @ObservedObject private var communicationWebSocket = CommunicationWebSocketManager.shared
    @ObservedObject private var globalStateManager = GlobalStateManager.shared

    @Binding var isPresented: Bool
    @State private var username: String = ""
    @State private var gameCode: String = ""
    @FocusState private var isUsernameFieldFocused: Bool
    @State private var isCheckingValidity = false
    @State private var showAlert = false
    @State private var showGameCodeAlert = false
    @State private var alertType: AlertType?
    var onJoinGame: () -> Void

    enum AlertType: Identifiable {
        case usernameInUse
        case gameCodeInvalid
        case gameInProgress
        case gameFull

        var id: Int {
            switch self {
            case .usernameInUse:
                return 1
            case .gameCodeInvalid:
                return 2
            case .gameInProgress:
                return 3
            case .gameFull:
                return 4
            }
        }
    }

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
                    .textInputAutocapitalization(.never)
                    .padding()
                    .onChange(of: username) { newValue in
                        username = newValue.lowercased()
                    }
                    .focused($isUsernameFieldFocused)

                Spacer()

                Text("Enter your game code!")
                    .font(.title2)
                    .bold()
                    .padding()

                GameCodeInput(code: $gameCode)
                    .padding(.horizontal)
                    .padding(.bottom)

                if isCheckingValidity {
                    ProgressView() // Activity indicator
                }

                Spacer()
            }
            .navigationBarItems(trailing: Button("Next") {
                performValidityCheck()
            }
            .disabled(username.isEmpty || gameCode.count != 6))
            .onAppear {
                DispatchQueue.main.async {
                    self.isUsernameFieldFocused = true
                }

                if !drawingWebSocket.isDrawingSocketConnected {
                    drawingWebSocket.establishDrawingSocketConnection()
                }

                if !communicationWebSocket.isCommunicationSocketConnected {
                    communicationWebSocket.setupCommunicationSocket()
                }
            }
            .onReceive(globalStateManager.$usernameInUse) { usernameInUse in
                if usernameInUse {
                    alertType = .usernameInUse
                }
            }
            .onReceive(globalStateManager.$gameCodeInvalid) { gameCodeInvalid in
                if gameCodeInvalid {
                    alertType = .gameCodeInvalid
                }
            }
            .onReceive(globalStateManager.$gameInProgress) { gameCodeInProgress in
                if gameCodeInProgress {
                    alertType = .gameInProgress
                }
            }
            .onReceive(globalStateManager.$gameFull) { gameFull in
                if gameFull {
                    alertType = .gameFull
                }
            }
            .alert(item: $alertType) { type in
                switch type {
                case .usernameInUse:
                    return Alert(
                        title: Text("Username is in use for this game, please provide a different username."),
                        dismissButton: .default(Text("OK")) {
                            globalStateManager.setUsernameInUse(isUsernameInUse: false)
                            username = ""
                            isCheckingValidity = false
                        }
                    )
                case .gameCodeInvalid:
                    return Alert(
                        title: Text("Game code is invalid, please try again."),
                        dismissButton: .default(Text("OK")) {
                            globalStateManager.setGameCodeInvalid(isGameCodeInvalid: false)
                            gameCode = ""
                            isCheckingValidity = false
                        }
                    )
                case .gameInProgress:
                    return Alert(
                        title: Text("Game is already in progress, please provide a different game to join."),
                        dismissButton: .default(Text("OK")) {
                            globalStateManager.setGameInProgress(isGameInProgress: false)
                            gameCode = ""
                            isCheckingValidity = false
                        }
                    )
                case .gameFull:
                    return Alert(
                        title: Text("Game is already full, please provide a different game to join."),
                        dismissButton: .default(Text("OK")) {
                            globalStateManager.setGameFull(isGameFull: false)
                            gameCode = ""
                            isCheckingValidity = false
                        }
                    )
                }
            }
        }
    }

    private func performValidityCheck() {
        isCheckingValidity = true
        checkUsername()
        checkGameCode()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            evaluateNavigationConditions()
        }
    }

    private func evaluateNavigationConditions() {
        if globalStateManager.usernameInUse || globalStateManager.gameCodeInvalid || globalStateManager.gameInProgress || globalStateManager.gameFull {
            return
        }

        // If none of the errors are true and checks are completed, navigate
        if isCheckingValidity {
            globalStateManager.setUsername(usernameToSet: username)
            globalStateManager.setGameCode(gameCodeToSet: gameCode)
            isCheckingValidity = false
            onJoinGame()
        }
    }

    private func checkUsername() {
        guard !username.isEmpty && gameCode.count == 6 else { return }

        let data = [
            "action": "checkUsernameExistsForGame",
            "gameCode": gameCode,
            "username": username
        ]

        communicationWebSocket.sendCommunicationMessage(data)
    }

    private func checkGameCode() {
        guard gameCode.count == 6 else { return }

        let data = [
            "action": "checkGameCode",
            "gameCode": gameCode
        ]

        communicationWebSocket.sendCommunicationMessage(data)
    }
}

struct GameCodeInput: View {
    @Binding var code: String
    let codeLength = 6
    @FocusState private var isInputActive: Bool
    @State private var cursorVisible = false
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $code)
                .focused($isInputActive)
                .font(.title)
                .foregroundColor(.clear)
                .accentColor(.orange)
                .keyboardType(.default)
                .textContentType(.oneTimeCode)
                .onChange(of: code) { newValue in
                    if newValue.count > codeLength {
                        code = String(newValue.prefix(codeLength))
                    }
                    code = code.uppercased()
                }
                .frame(width: CGFloat(codeLength) * 44, height: 55)
                .opacity(0.01)

            HStack(spacing: 15) {
                ForEach(0 ..< codeLength, id: \.self) { index in
                    Text(code.count > index ? String(code[code.index(code.startIndex, offsetBy: index)]) : "")
                        .font(.title)
                        .frame(width: 44, height: 55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }

            if isInputActive && code.count < codeLength {
                Rectangle()
                    .frame(width: 28, height: 3)
                    .foregroundColor(.orange)
                    .opacity(cursorVisible ? 1 : 0)
                    .cornerRadius(1)
                    .offset(x: CGFloat(code.count) * (44 + 15) + 8, y: 21)
                    .onReceive(timer) { _ in
                        self.cursorVisible.toggle()
                    }
            }
        }
        .onTapGesture {
            self.isInputActive = true
        }
    }
}
