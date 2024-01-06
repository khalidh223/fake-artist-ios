import Foundation
import SocketIO

class DrawingWebSocketManager: ObservableObject {
    static let shared = DrawingWebSocketManager()

    var drawingSocket: SocketIOClient
    let drawingSocketManager: SocketManager
    @Published var isDrawingSocketConnected = false
    private let drawingSocketURL = URL(string: ProcessInfo.processInfo.environment["DRAWING_WEBSOCKET_URL"] ?? "No url defined")!

    init() {
        self.drawingSocketManager = SocketManager(socketURL: drawingSocketURL, config: [.log(true), .compress])
        self.drawingSocket = drawingSocketManager.defaultSocket
    }

    func establishDrawingSocketConnection() {
        drawingSocket.connect()
        setupEventListeners()
        isDrawingSocketConnected = true
    }

    private func setupEventListeners() {
        drawingSocket.on("gameStarted") { [weak self] _, _ in
            guard let self = self else { return }
            // Perform the action when gameStarted is received
            self.handleGameStarted()
        }
    }

    private func handleGameStarted() {
        let gameCode = GlobalStateManager.shared.gameCode
        let connectionId = GlobalStateManager.shared.communicationConnectionId
        CanvasCommunicationWebSocketManager.shared.sendRoleToPlayers(gameCode: gameCode, playerConnectionId: connectionId)
    }

    func closeDrawingSocketConnection() {
        drawingSocket.disconnect()
        isDrawingSocketConnected = false
    }

    func sendDrawingMessage(_ action: String, data: Any) {
        if drawingSocket.status == .connected {
            drawingSocket.emit(action, data as! SocketData)
        } else {
            print("Drawing socket is not connected. Cannot send message.")
        }
    }
}
