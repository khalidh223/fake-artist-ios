import Foundation

class CanvasCommunicationWebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = CanvasCommunicationWebSocketManager()
    
    var canvasCommunicationWebSocket: URLSessionWebSocketTask?
    private let canvasCommunicationSocketURL = URL(string: ProcessInfo.processInfo.environment["COMMUNICATION_WEBSOCKET_URL"] ?? "No url defined")!
    
    override init() {
        super.init()
        setupCanvasCommunicationSocket()
    }
    
    func setupCanvasCommunicationSocket() {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        canvasCommunicationWebSocket = urlSession.webSocketTask(with: canvasCommunicationSocketURL)

        canvasCommunicationWebSocket?.resume()
        print("Attempting to connect to WebSocket at \(canvasCommunicationSocketURL)")
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
        return canvasCommunicationWebSocket?.state == .running
    }

    func sendWebSocketMessage(data: String) {
        if !isCommunicationSocketConnected {
            print("WebSocketManager: Communication socket not connected, reconnecting")
            setupCanvasCommunicationSocket()
        }
        let message = URLSessionWebSocketTask.Message.string(data)
        canvasCommunicationWebSocket?.send(message) { error in
            if let error = error {
                print("WebSocketManager: Error sending message: \(error)")
            } else {
                print("WebSocketManager: Message sent successfully")
            }
        }
    }
    
    func sendRequestRole(gameCode: String, playerConnectionId: String) {
        let data: [String: Any] = [
            "action": "requestRole",
            "gameCode": gameCode,
            "playerConnectionId": playerConnectionId
        ]
        sendCommunicationMessage(data)
    }
    
    func sendPlayerStoppedDrawing(username: String, gameCode: String) {
        let data: [String: Any] = [
            "action": "sendPlayerStoppedDrawing",
            "username": username,
            "gameCode": gameCode
        ]
        sendCommunicationMessage(data)
    }
    
    func sendStopGame(gameCode: String) {
        let data: [String: Any] = [
            "action": "sendStopGame",
            "gameCode": gameCode
        ]
        sendCommunicationMessage(data)
    }
    
    func sendVoteForFakeArtist(votedFor: String, username: String, gameCode: String) {
        let data: [String: Any] = [
            "action": "sendVoteForFakeArtist",
            "gameCode": gameCode,
            "username": username,
            "votedForPlayer": votedFor
        ]
        sendCommunicationMessage(data)
    }

    func disconnect() {
        canvasCommunicationWebSocket?.cancel()
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
