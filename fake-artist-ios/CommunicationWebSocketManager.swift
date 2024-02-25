import Foundation

class CommunicationWebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = CommunicationWebSocketManager()
    
    var communicationSocket: URLSessionWebSocketTask?
    private let communicationSocketURL = URL(string: ProcessInfo.processInfo.environment["COMMUNICATION_WEBSOCKET_URL"] ?? "No url defined")!
    
    override init() {
        super.init()
        setupCommunicationSocket()
    }
    
    func setupCommunicationSocket() {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        communicationSocket = urlSession.webSocketTask(with: communicationSocketURL)

        communicationSocket?.resume()
        print("Attempting to connect to WebSocket at \(communicationSocketURL)")
        receiveMessageFromCommunicationSocket()
    }
    
    func receiveMessageFromCommunicationSocket() {
        communicationSocket?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
                self?.handleCommunicationSocketError(error)
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleReceivedString(text)
                case .data(let data):
                    print("Received data: \(data)")
                default:
                    print("Received unknown message type")
                }
                self?.receiveMessageFromCommunicationSocket()
            }
        }
    }
    
    func handleCommunicationSocketError(_ error: Error) {
        // Additional error handling logic can be added here
        print("Communication socket encountered an error: \(error.localizedDescription)")
    }
    
    func handleReceivedString(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dictionary = json as? [String: Any],
              let action = dictionary["action"] as? String
        else {
            print("WebSocketManager: Failed to parse JSON or 'action' not found")
            return
        }

        print("WebSocketManager: Received action - \(action)")
        switch action {
        case "updatePlayers":
            if let players = dictionary["players"] as? [String] {
                handleUpdatePlayersAction(players)
            }
        case "gameLeft":
            if let username = dictionary["username"] as? String {
                handleGameLeftAction(username)
            }
        case "connectionEstablished":
            if let connectionId = dictionary["connectionId"] as? String {
                handleConnectionEstablishedAction(connectionId)
            }
        case "gameEnded":
            GlobalStateManager.shared.setGameEnded(isGameEnded: true)
        case "gameCodeInvalid":
            GlobalStateManager.shared.setGameCodeInvalid(isGameCodeInvalid: true)
        case "usernameInUse":
            GlobalStateManager.shared.setUsernameInUse(isUsernameInUse: true)
        case "gameInProgress":
            GlobalStateManager.shared.setGameInProgress(isGameInProgress: true)
        case "gameFull":
            GlobalStateManager.shared.setGameFull(isGameFull: true)
        case "roleForPlayer":
            if let role = dictionary["role"] as? String {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.setPlayerRole(role)
                }
            }
        case "setColorChosen":
            if let color = dictionary["colorChosen"] as? String, let username = dictionary["username"] as? String {
                GlobalStateManager.shared.setColorToUsernameMap(color: color, username: username)
            }
        case "colorConfirmed":
            if let color = dictionary["color"] as? String, let username = dictionary["username"] as? String {
                GlobalStateManager.shared.setConfirmedColorForPlayer(color: color, username: username)
            }
        case "allPlayersConfirmedColor":
            if let allPlayersConfirmed = dictionary["allPlayersConfirmedColor"] as? Bool, allPlayersConfirmed {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.allPlayersConfirmedColor = true
                }
            }
        case "setThemeChosenByQuestionMaster":
            if let theme = dictionary["theme"] as? String {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.themeChosenByQuestionMaster = theme
                }
            }
        case "setTitleChosenByQuestionMaster":
            if let title = dictionary["title"] as? String {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.titleChosenByQuestionMaster = title
                }
            }
        case "nextPlayerToDraw":
            if let currentPlayerDrawing = dictionary["next_player"] as? String {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.currentPlayerDrawing = currentPlayerDrawing
                }
            }
        case "assignedQuestionMaster":
            if let questionMaster = dictionary["questionMaster"] as? String {
                DispatchQueue.main.async {
                    GlobalStateManager.shared.questionMaster = questionMaster
                }
            }
        case "setStopGame":
            DispatchQueue.main.async {
                GlobalStateManager.shared.stoppedGame = true
            }
        default:
            print("WebSocketManager: Received action: \(action)")
        }
    }
    
    func handleUpdatePlayersAction(_ players: [String]) {
        DispatchQueue.main.async {
            print("WebSocketManager: Updating players")
            GlobalStateManager.shared.players = players
        }
    }

    func handleGameLeftAction(_ username: String) {
        DispatchQueue.main.async {
            print("WebSocketManager: Removing player - \(username)")
            GlobalStateManager.shared.players.removeAll { $0 == username }
        }
    }

    func handleConnectionEstablishedAction(_ connectionId: String) {
        DispatchQueue.main.async {
            print("WebSocketManager: Setting communication connection ID")
            GlobalStateManager.shared.setCommunicationConnectionId(connectionId: connectionId)
        }
    }
    
    func sendCommunicationMessage(_ data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sendWebSocketMessage(data: jsonString)
            }
        } catch {
            print("WebSocketManager: Error serializing message data to JSON: \(error)")
        }
    }
    
    var isCommunicationSocketConnected: Bool {
        return communicationSocket?.state == .running
    }

    func sendWebSocketMessage(data: String) {
        if !isCommunicationSocketConnected {
            print("WebSocketManager: Communication socket not connected, reconnecting")
            setupCommunicationSocket()
        }
        let message = URLSessionWebSocketTask.Message.string(data)
        communicationSocket?.send(message) { error in
            if let error = error {
                print("WebSocketManager: Error sending message: \(error)")
            } else {
                print("WebSocketManager: Message sent successfully")
            }
        }
    }
    
    func sendLeaveGameMessage(gameCode: String, username: String) {
        let leaveGameData: [String: Any] = [
            "action": "leaveGame",
            "gameCode": gameCode,
            "username": username
        ]
        sendCommunicationMessage(leaveGameData)
    }

    func disconnect() {
        communicationSocket?.cancel()
        print("WebSocketManager: WebSocket connections closed")
    }
    
    // URLSessionWebSocketDelegate methods
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocketManager: WebSocket connection opened")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocketManager: WebSocket connection closed with code \(closeCode)")
    }
}
