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
            self.handleGameStarted()
        }
        drawingSocket.on("drawingData") { [weak self] data, _ in
            guard let self = self else { return }
            self.handleDrawingData(data.first as? [String: Any] ?? [:])
        }
    }

    private func handleGameStarted() {
        let gameCode = GlobalStateManager.shared.gameCode
        let connectionId = GlobalStateManager.shared.communicationConnectionId
        CanvasCommunicationWebSocketManager.shared.sendRequestRole(gameCode: gameCode, playerConnectionId: connectionId)
    }

    @Published var receivedDrawingData: DrawingData?

    private func handleDrawingData(_ data: [String: Any]) {
        guard let x = data["x"] as? Double,
              let y = data["y"] as? Double,
              let prevX = data["prevX"] as? Double,
              let prevY = data["prevY"] as? Double,
              let color = data["color"] as? String
        else {
            return
        }

        DispatchQueue.main.async {
            self.receivedDrawingData = DrawingData(x: x, y: y, prevX: prevX, prevY: prevY, color: color)
        }
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
